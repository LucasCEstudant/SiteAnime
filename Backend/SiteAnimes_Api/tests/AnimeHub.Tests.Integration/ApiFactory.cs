using AnimeHub.Application.Dtos.External;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.AniList;
using AnimeHub.Infrastructure.External.Common;
using AnimeHub.Infrastructure.External.Jikan;
using AnimeHub.Infrastructure.External.Kitsu;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace AnimeHub.Tests.Integration;

public class ApiFactory : WebApplicationFactory<Program>
{
    private SqliteConnection? _connection;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            // --- DB: troca SQL Server por SQLite in-memory ---
            services.RemoveAll(typeof(DbContextOptions<AppDbContext>));
            services.RemoveAll(typeof(DbContextOptions));
            services.RemoveAll(typeof(IDbContextOptionsConfiguration<AppDbContext>));

            _connection = new SqliteConnection("DataSource=:memory:");
            _connection.Open();

            services.AddDbContext<AppDbContext>(options => options.UseSqlite(_connection));

            // --- Search agregado: fake providers (sem rede) ---
            services.RemoveAll(typeof(IAnimeExternalProvider));
            services.AddSingleton<IAnimeExternalProvider>(new FakeProvider("Jikan"));
            services.AddSingleton<IAnimeExternalProvider>(new FakeProvider("AniList"));
            services.AddSingleton<IAnimeExternalProvider>(new FakeProvider("Kitsu"));

            // --- Clients externos (sem rede) ---
            services.RemoveAll(typeof(AniListClient));
            services.RemoveAll(typeof(KitsuClient));
            services.RemoveAll(typeof(JikanClient));

            services.AddSingleton(_ =>
            {
                var http = new HttpClient(new FakeAniListHandler())
                {
                    BaseAddress = new Uri("https://graphql.anilist.co/"),
                    Timeout = TimeSpan.FromSeconds(15)
                };

                return new AniListClient(new AnimeHub.Infrastructure.External.Common.GraphQlClient(http));
            });

            services.AddSingleton(_ =>
                new KitsuClient(new HttpClient(new FakeKitsuHandler())
                {
                    BaseAddress = new Uri("https://kitsu.io/api/edge/")
                }));

            services.AddSingleton(_ =>
            {
                var http = new HttpClient(new FakeJikanHandler())
                {
                    BaseAddress = new Uri("https://api.jikan.moe/v4/"),
                    Timeout = TimeSpan.FromSeconds(15)
                };

                var rest = new RestJsonClient(http);
                return new JikanClient(rest);
            });

            // Cache em testes
            services.AddMemoryCache();

            // Rate limiters: em testes queremos determinístico (sem flakiness por paralelismo)
            services.RemoveAll(typeof(JikanRateLimiter));
            services.RemoveAll(typeof(AniListRateLimiter));
            services.RemoveAll(typeof(KitsuRateLimiter));

            services.AddTransient<JikanRateLimiter>();
            services.AddTransient<AniListRateLimiter>();
            services.AddTransient<KitsuRateLimiter>();

            // --- Schema + seed admin ---
            using var sp = services.BuildServiceProvider();
            using var scope = sp.CreateScope();

            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Database.EnsureCreated();

            if (!db.Users.Any())
            {
                db.Users.Add(new AnimeHub.Domain.Entities.User
                {
                    Email = "admin@animehub.local",
                    PasswordHash = AnimeHub.Infrastructure.Auth.PasswordHasher.Hash("Admin@12345"),
                    Role = "Admin",
                    CreatedAtUtc = DateTime.UtcNow
                });

                db.SaveChanges();
            }
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        _connection?.Dispose();
    }

    // -----------------------------------------------------------------------
    // Fakes
    // -----------------------------------------------------------------------

    private sealed class FakeProvider : IAnimeExternalProvider
    {
        public string Provider { get; }
        public FakeProvider(string provider) => Provider = provider;

        public Task<List<ExternalAnimeDto>> SearchAsync(string q, int pageOrOffset, int limit, CancellationToken ct)
        {
            q = (q ?? "").Trim();
            if (q.Length == 0)
                return Task.FromResult(new List<ExternalAnimeDto>());

            var item = new ExternalAnimeDto(
                Provider: Provider,
                ExternalId: $"fake-{Provider}-{q}-{pageOrOffset}",
                Title: $"{q} ({Provider})",
                Synopsis: null,
                Year: 2000,
                Score: 8.0m,
                CoverUrl: null,
                Genres: ["Action", "Adventure"]
            );

            return Task.FromResult(new List<ExternalAnimeDto> { item });
        }

        public Task<ExternalAnimeDto?> GetByIdAsync(string externalId, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(externalId))
                return Task.FromResult<ExternalAnimeDto?>(null);

            var dto = new ExternalAnimeDto(
                Provider: Provider,
                ExternalId: externalId,
                Title: $"Anime {externalId} ({Provider})",
                Synopsis: null,
                Year: 2000,
                Score: 8.0m,
                CoverUrl: null,
                Genres: ["Action", "Adventure"]
            );

            return Task.FromResult<ExternalAnimeDto?>(dto);
        }
    }

    private sealed class FakeAniListHandler : HttpMessageHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var body = request.Content is null
                ? ""
                : await request.Content.ReadAsStringAsync(cancellationToken);

            if (body.Contains("GenreCollection", StringComparison.OrdinalIgnoreCase))
            {
                var json = """
                {
                    "data": {
                    "GenreCollection": ["Action", "Adventure", "Comedy"]
                    }
                }
                """;

                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                };
            }

            // Se a query usa Page(...) => filtros/pesquisa (data.Page.media)
            if (body.Contains("Page(", StringComparison.OrdinalIgnoreCase))
            {
                // Se year não veio no controller (vira 0) e isso chega no AniList,
                // devolvemos lista vazia para ficar "realista".
                if (body.Contains("\"year\":0", StringComparison.OrdinalIgnoreCase) ||
                    body.Contains("\"year\": 0", StringComparison.OrdinalIgnoreCase) ||
                    body.Contains("\"seasonYear\":0", StringComparison.OrdinalIgnoreCase) ||
                    body.Contains("\"seasonYear\": 0", StringComparison.OrdinalIgnoreCase) ||
                    body.Contains("seasonYear:0", StringComparison.OrdinalIgnoreCase) ||
                    body.Contains("seasonYear: 0", StringComparison.OrdinalIgnoreCase)
                )
                {
                    var empty = """
                    {
                        "data": {
                        "Page": {
                            "media": []
                        }
                        }
                    }
                    """;

                    return new HttpResponseMessage(HttpStatusCode.OK)
                    {
                        Content = new StringContent(empty, Encoding.UTF8, "application/json")
                    };
                }

                var json = """
                {
                  "data": {
                    "Page": {
                      "media": [
                        {
                          "id": 123,
                          "title": { "userPreferred": "Fake AniList Anime" },
                          "description": "desc",
                          "startDate": { "year": 2019 },
                          "averageScore": 80,
                          "coverImage": { "large": "https://img.example/anilist.jpg" },
                          "genres": ["Action", "Fantasy"]
                        }
                      ]
                    }
                  }
                }
                """;

                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                };
            }

            // Caso contrário => detalhe por Media(id: ...) (data.Media)
            // ID sentinela para simular inexistente no detalhe (retorna 404 como a doc descreve). :contentReference[oaicite:2]{index=2}
            if (body.Contains("\"id\":999999", StringComparison.OrdinalIgnoreCase)
                || body.Contains("\"id\": 999999", StringComparison.OrdinalIgnoreCase))
            {
                return new HttpResponseMessage(HttpStatusCode.NotFound);
            }

            var detailJson = """
            {
              "data": {
                "Media": {
                  "id": 123,
                  "title": { "userPreferred": "Fake AniList Anime" },
                  "description": "desc",
                  "startDate": { "year": 2019 },
                  "averageScore": 80,
                  "episodes": 12,
                  "duration": 24,
                  "coverImage": { "large": "https://img.example/anilist.jpg" },
                  "genres": ["Action", "Fantasy"],
                  "externalLinks": [{ "site": "Crunchyroll", "url": "https://cr.example" }],
                  "streamingEpisodes": [{ "title": "Ep 1", "url": "https://stream.example/1", "site": "Crunchyroll" }]
                }
              }
            }
            """;

            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(detailJson, Encoding.UTF8, "application/json")
            };
        }
    }

    private sealed class FakeKitsuHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var path = request.RequestUri?.AbsolutePath ?? "";

            // ID sentinela de detalhe inexistente
            if (path.EndsWith("/anime/does-not-exist", StringComparison.OrdinalIgnoreCase))
            {
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NotFound));
            }

            // Detalhe: /anime/{id} => { data: { ... } }
            if (path.Contains("/anime/", StringComparison.OrdinalIgnoreCase))
            {
                var json = """
                {
                  "data": {
                    "id": "kitsu-1",
                    "attributes": {
                      "canonicalTitle": "Fake Kitsu Anime",
                      "synopsis": "desc",
                      "startDate": "2018-01-01",
                      "averageRating": "85.0",
                      "episodeCount": 24,
                      "episodeLength": 24,
                      "youtubeVideoId": null,
                      "posterImage": { "large": "https://img.example/kitsu.jpg" }
                    },
                    "relationships": {
                      "categories": {
                        "data": [
                          { "type": "categories", "id": "1" },
                          { "type": "categories", "id": "2" }
                        ]
                      }
                    }
                  },
                  "included": [
                    { "type": "categories", "id": "1", "attributes": { "title": "Sci-Fi" } },
                    { "type": "categories", "id": "2", "attributes": { "title": "Mecha" } }
                  ]
                }
                """;

                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                });
            }

            // Lista/pesquisa: { data: [ ... ] }
            var listJson = """
            {
              "data": [
                {
                  "id": "kitsu-1",
                  "attributes": {
                    "canonicalTitle": "Fake Kitsu Anime",
                    "synopsis": "desc",
                    "startDate": "2018-01-01",
                    "averageRating": "85.0",
                    "episodeCount": 24,
                    "episodeLength": 24,
                    "youtubeVideoId": null,
                    "posterImage": { "large": "https://img.example/kitsu.jpg" }
                  },
                  "relationships": {
                    "categories": {
                      "data": [
                        { "type": "categories", "id": "1" },
                        { "type": "categories", "id": "2" }
                      ]
                    }
                  }
                }
              ],
              "included": [
                { "type": "categories", "id": "1", "attributes": { "title": "Sci-Fi" } },
                { "type": "categories", "id": "2", "attributes": { "title": "Mecha" } }
              ]
            }
            """;

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(listJson, Encoding.UTF8, "application/json")
            });
        }
    }

    private sealed class FakeJikanHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var path = request.RequestUri?.AbsolutePath ?? "";

            // ID sentinela para simular detalhe inexistente
            if (path.Contains("/anime/999999/full", StringComparison.OrdinalIgnoreCase))
            {
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NotFound));
            }

            // detalhe: /v4/anime/{id}/full
            if (path.Contains("/anime/", StringComparison.OrdinalIgnoreCase) &&
                path.Contains("/full", StringComparison.OrdinalIgnoreCase))
            {
                var json = """
                {
                  "data": {
                    "mal_id": 5114,
                    "title": "Fake Jikan Full Anime",
                    "synopsis": "desc",
                    "year": 2026,
                    "score": 8.5,
                    "episodes": 24,
                    "duration": "24",
                    "images": { "jpg": { "image_url": "https://img.example/jikan.jpg" } },
                    "genres": [
                      { "mal_id": 1, "name": "Action" },
                      { "mal_id": 2, "name": "Adventure" }
                    ]
                  }
                }
                """;

                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                });
            }

            // season now: /v4/seasons/now
            if (path.Contains("/seasons/now", StringComparison.OrdinalIgnoreCase))
            {
                var json = """
                {
                  "data": [
                    {
                      "mal_id": 5114,
                      "title": "Fake Jikan Season Anime",
                      "synopsis": "desc",
                      "year": 2026,
                      "score": 8.5,
                      "episodes": 24,
                      "duration": "24",
                      "images": { "jpg": { "image_url": "https://img.example/jikan.jpg" } },
                      "genres": [
                        { "mal_id": 1, "name": "Action" },
                        { "mal_id": 2, "name": "Adventure" }
                      ]
                    }
                  ]
                }
                """;

                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                });
            }

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NotFound));
        }
    }

    public async Task<(string AccessToken, string RefreshToken)> AuthenticateAdminAsync(HttpClient client, CancellationToken ct)
    {
        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "admin@animehub.local",
            password = "Admin@12345"
        }, ct);

        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: ct);

        return (
            AccessToken: json.GetProperty("accessToken").GetString() ?? "",
            RefreshToken: json.GetProperty("refreshToken").GetString() ?? ""
        );
    }
}