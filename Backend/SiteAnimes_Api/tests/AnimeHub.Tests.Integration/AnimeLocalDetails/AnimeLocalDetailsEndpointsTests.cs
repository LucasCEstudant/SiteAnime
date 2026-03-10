using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;

namespace AnimeHub.Tests.Integration.AnimeLocalDetails;

public class AnimeLocalDetailsEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public AnimeLocalDetailsEndpointsTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task PutDetails_DeveRetornar401_SemToken()
    {
        var id = await SeedLocalAnimeAsync();

        var resp = await _client.PutAsJsonAsync($"/api/animes/{id}/details", new
        {
            episodeCount = 12,
            episodeLengthMinutes = 24,
            externalLinks = new[] { new { site = "Site", url = "https://example.com" } },
            streamingEpisodes = new[] { new { title = "Ep 1", url = "https://stream/1", site = "Provider" } }
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task PutDetails_DeveAtualizarERetornar204_ComAdmin_E_GetDeveRetornarConteudo()
    {
        var id = await SeedLocalAnimeAsync();
        await AuthorizeAsAdminAsync();

        // PUT (204 No Content é esperado) :contentReference[oaicite:2]{index=2}
        var put = await _client.PutAsJsonAsync($"/api/animes/{id}/details", new
        {
            episodeCount = 100,
            episodeLengthMinutes = 24,
            externalLinks = new[] { new { site = "Crunchyroll", url = "https://cr.example" } },
            streamingEpisodes = new[] { new { title = "Ep 1", url = "https://stream.example/1", site = "Crunchyroll" } }
        }, TestContext.Current.CancellationToken);

        put.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // GET details local
        var get = await _client.GetAsync($"/api/animes/{id}/details", TestContext.Current.CancellationToken);
        get.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await get.Content.ReadFromJsonAsync<LocalDetailsDto>(cancellationToken: TestContext.Current.CancellationToken);
        payload.Should().NotBeNull();
        payload!.Id.Should().Be(id);
        payload.EpisodeCount.Should().Be(100);
        payload.EpisodeLengthMinutes.Should().Be(24);
        payload.ExternalLinks.Should().HaveCount(1);
        payload.StreamingEpisodes.Should().HaveCount(1);
    }

    [Fact]
    public async Task DetailsUnificado_Local_DeveConter_DetalhesSalvos()
    {
        var id = await SeedLocalAnimeAsync();
        await AuthorizeAsAdminAsync();

        // atualiza details
        var put = await _client.PutAsJsonAsync($"/api/animes/{id}/details", new
        {
            episodeCount = 10,
            episodeLengthMinutes = 25,
            externalLinks = new[] { new { site = "Site", url = "https://example.com" } },
            streamingEpisodes = new[] { new { title = "Ep 1", url = "https://stream/1", site = "Provider" } }
        }, TestContext.Current.CancellationToken);

        put.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // chama endpoint unificado
        var get = await _client.GetAsync($"/api/animes/details?source=local&id={id}", TestContext.Current.CancellationToken);
        get.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await get.Content.ReadFromJsonAsync<UnifiedDetailsDto>(cancellationToken: TestContext.Current.CancellationToken);
        payload.Should().NotBeNull();
        payload!.Source.Should().Be("local");
        payload.Id.Should().Be(id);
        payload.EpisodeCount.Should().Be(10);
        payload.EpisodeLength.Should().Be(25);
        payload.ExternalLinks.Should().NotBeEmpty();
        payload.StreamingEpisodes.Should().NotBeEmpty();
    }

    // ---------------- NEGATIVOS ----------------

    [Fact]
    public async Task GetDetails_DeveRetornar404_QuandoIdInexistente()
    {
        var resp = await _client.GetAsync("/api/animes/999999/details",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task PutDetails_DeveRetornar404_QuandoIdInexistente_ComAdmin()
    {
        await AuthorizeAsAdminAsync();

        var resp = await _client.PutAsJsonAsync("/api/animes/999999/details", new
        {
            episodeCount = 12,
            episodeLengthMinutes = 24,
            externalLinks = Array.Empty<object>(),
            streamingEpisodes = Array.Empty<object>()
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task PutDetails_DeveRetornar401_QuandoTokenInvalido()
    {
        var id = await SeedLocalAnimeAsync();

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "token_invalido");

        var resp = await _client.PutAsJsonAsync($"/api/animes/{id}/details", new
        {
            episodeCount = 12,
            episodeLengthMinutes = 24,
            externalLinks = Array.Empty<object>(),
            streamingEpisodes = Array.Empty<object>()
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task PutDetails_DeveRetornar403_ComUsuarioComum()
    {
        var id = await SeedLocalAnimeAsync();
        await EnsureCommonUserExistsAsync();
        await AuthorizeAsCommonAsync();

        var resp = await _client.PutAsJsonAsync($"/api/animes/{id}/details", new
        {
            episodeCount = 12,
            episodeLengthMinutes = 24,
            externalLinks = Array.Empty<object>(),
            streamingEpisodes = Array.Empty<object>()
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ---------------- helpers ----------------

    private async Task<int> SeedLocalAnimeAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var entity = new AnimeHub.Domain.Entities.Anime
        {
            Title = "Local Anime",
            Synopsis = "Local desc",
            Year = 2020,
            Score = 9.1m,
            CoverUrl = null,
            CreatedAtUtc = DateTime.UtcNow
        };

        db.Animes.Add(entity);
        await db.SaveChangesAsync(TestContext.Current.CancellationToken);

        return entity.Id;
    }


    private async Task EnsureCommonUserExistsAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var email = "user@animehub.local";
        if (db.Users.Any(x => x.Email == email)) return;

        db.Users.Add(new AnimeHub.Domain.Entities.User
        {
            Email = email,
            PasswordHash = AnimeHub.Infrastructure.Auth.PasswordHasher.Hash("User@12345"),
            Role = "", // comum (sem role)
            CreatedAtUtc = DateTime.UtcNow
        });

        await db.SaveChangesAsync(TestContext.Current.CancellationToken);
    }

    private async Task AuthorizeAsCommonAsync()
    {
        var login = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "user@animehub.local",
            password = "User@12345"
        }, TestContext.Current.CancellationToken);

        login.StatusCode.Should().Be(HttpStatusCode.OK);

        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(
            cancellationToken: TestContext.Current.CancellationToken);

        auth.Should().NotBeNull();
        auth!.AccessToken.Should().NotBeNullOrWhiteSpace();

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth.AccessToken);
    }

    private async Task AuthorizeAsAdminAsync()
    {
        // login real (sem inventar JWT) — padrão de teste de endpoint protegido :contentReference[oaicite:3]{index=3}
        var login = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "admin@animehub.local",
            password = "Admin@12345"
        }, TestContext.Current.CancellationToken);

        login.StatusCode.Should().Be(HttpStatusCode.OK);

        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(cancellationToken: TestContext.Current.CancellationToken);
        auth.Should().NotBeNull();
        auth!.AccessToken.Should().NotBeNullOrWhiteSpace();

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);
    }

    private sealed class AuthResponse
    {
        [JsonPropertyName("accessToken")]
        public string AccessToken { get; set; } = string.Empty;
    }

    private sealed class LocalDetailsDto
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("episodeCount")]
        public int? EpisodeCount { get; set; }

        [JsonPropertyName("episodeLengthMinutes")]
        public int? EpisodeLengthMinutes { get; set; }

        [JsonPropertyName("externalLinks")]
        public List<LinkDto> ExternalLinks { get; set; } = new();

        [JsonPropertyName("streamingEpisodes")]
        public List<EpisodeDto> StreamingEpisodes { get; set; } = new();
    }

    private sealed class UnifiedDetailsDto
    {
        [JsonPropertyName("source")]
        public string Source { get; set; } = "";

        [JsonPropertyName("id")]
        public int? Id { get; set; }

        [JsonPropertyName("episodeCount")]
        public int? EpisodeCount { get; set; }

        [JsonPropertyName("episodeLength")]
        public int? EpisodeLength { get; set; }

        [JsonPropertyName("externalLinks")]
        public List<LinkDto> ExternalLinks { get; set; } = new();

        [JsonPropertyName("streamingEpisodes")]
        public List<EpisodeDto> StreamingEpisodes { get; set; } = new();
    }

    private sealed class LinkDto
    {
        [JsonPropertyName("site")]
        public string Site { get; set; } = "";

        [JsonPropertyName("url")]
        public string Url { get; set; } = "";
    }

    private sealed class EpisodeDto
    {
        [JsonPropertyName("title")]
        public string Title { get; set; } = "";

        [JsonPropertyName("url")]
        public string Url { get; set; } = "";

        [JsonPropertyName("site")]
        public string? Site { get; set; }
    }
}