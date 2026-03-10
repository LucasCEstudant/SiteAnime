using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AnimeHub.Tests.Integration.AnimeFilters;

public class AnimeFiltersEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public AnimeFiltersEndpointsTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Genre_DeveRetornar_AniList_E_Kitsu_SemRede()
    {
        var response = await _client.GetAsync("/api/animes/filters/genre?genre=action&limit=12",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        payload.Items.Should().Contain(x => x.Source == "AniList");
        payload.Items.Should().Contain(x => x.Source == "Kitsu");

        // Todos os itens externos devem ter gêneros
        payload.Items.Should().OnlyContain(x => x.Genres != null && x.Genres.Count > 0);
    }

    [Fact]
    public async Task Year_DeveAgregar_Local_E_AniList_SemRede()
    {
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Ano 2019 A", 2019),
            new AnimeSeed("Ano 2019 B", 2019),
            new AnimeSeed("Ano 2020", 2020)
        });

        var response = await _client.GetAsync("/api/animes/filters/year?year=2019&limit=10",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        payload.Items.Should().Contain(x => x.Source == "local");
        payload.Items.Should().Contain(x => x.Source == "AniList");
    }

    [Fact]
    public async Task SeasonNow_DeveRetornar_Jikan_E_AniList_SemRede()
    {
        var response = await _client.GetAsync("/api/animes/filters/season/now?limit=12",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        payload.Items.Should().Contain(x => x.Source == "Jikan");
        payload.Items.Should().Contain(x => x.Source == "AniList");

        // Itens externos devem ter gêneros
        payload.Items.Should().OnlyContain(x => x.Genres != null && x.Genres.Count > 0);
    }

    // ---------------- NEGATIVOS ----------------

    [Fact]
    public async Task Genre_SemParametroGenre_DeveRetornar400()
    {
        var response = await _client.GetAsync("/api/animes/filters/genre?limit=12",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Genre_GenreVazio_DeveRetornar400()
    {
        var response = await _client.GetAsync("/api/animes/filters/genre?genre=&limit=12",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Genre_CursorInvalido_NaoDeveQuebrar_DeveRetornar200()
    {
        var response = await _client.GetAsync("/api/animes/filters/genre?genre=action&limit=12&cursor=CURSOR_LIXO@@@",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        // com fakes, deve vir algo de AniList/Kitsu
        payload!.Items.Should().NotBeNull();
    }

    [Fact]
    public async Task Year_SemParametroYear_DeveRetornar400_ProblemDetails_ComErroYear()
    {
        var resp = await _client.GetAsync("/api/animes/filters/year?limit=12",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();

        errors.TryGetProperty("Year", out var yearErrors).Should().BeTrue();
        yearErrors.ValueKind.Should().Be(JsonValueKind.Array);
        yearErrors.GetArrayLength().Should().BeGreaterThan(0);

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Year_YearInvalido_DeveRetornar400_ProblemDetails_ComErroYear()
    {
        var resp = await _client.GetAsync("/api/animes/filters/year?year=0&limit=12",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();

        errors.TryGetProperty("Year", out var yearErrors).Should().BeTrue();
        yearErrors.ValueKind.Should().Be(JsonValueKind.Array);
        yearErrors.GetArrayLength().Should().BeGreaterThan(0);

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Year_CursorInvalido_NaoDeveQuebrar_DeveRetornar200()
    {
        await ResetAnimesAsync();
        await SeedAnimesAsync(new[] { new AnimeSeed("Ano 2019 A", 2019) });

        var response = await _client.GetAsync("/api/animes/filters/year?year=2019&limit=12&cursor=CURSOR_LIXO@@@",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeNull();
    }

    [Fact]
    public async Task SeasonNow_CursorInvalido_NaoDeveQuebrar_DeveRetornar200()
    {
        var response = await _client.GetAsync("/api/animes/filters/season/now?limit=12&cursor=CURSOR_LIXO@@@",
            TestContext.Current.CancellationToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<FilterResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeNull();
    }

    // ---------- helpers ----------
    private async Task ResetAnimesAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.ExecuteSqlRawAsync("DELETE FROM Animes;", TestContext.Current.CancellationToken);
    }

    private async Task SeedAnimesAsync(IEnumerable<AnimeSeed> animes)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        foreach (var a in animes)
        {
            db.Animes.Add(new AnimeHub.Domain.Entities.Anime
            {
                Title = a.Title,
                Year = a.Year,
                CreatedAtUtc = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync(TestContext.Current.CancellationToken);
    }

    private sealed record AnimeSeed(string Title, int? Year);

    private sealed class FilterResponseDto
    {
        [JsonPropertyName("items")]
        public List<FilterItemDto> Items { get; set; } = new();

        [JsonPropertyName("nextCursor")]
        public string? NextCursor { get; set; }
    }

    private sealed class FilterItemDto
    {
        [JsonPropertyName("source")]
        public string Source { get; set; } = string.Empty;

        [JsonPropertyName("id")]
        public int? Id { get; set; }

        [JsonPropertyName("externalId")]
        public string? ExternalId { get; set; }

        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;

        [JsonPropertyName("genres")]
        public List<string> Genres { get; set; } = new();
    }
}