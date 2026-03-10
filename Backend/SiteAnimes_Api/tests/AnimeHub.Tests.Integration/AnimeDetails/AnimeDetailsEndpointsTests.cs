using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AnimeHub.Tests.Integration.AnimeDetails;

public class AnimeDetailsEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public AnimeDetailsEndpointsTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Details_Local_DeveRetornar200()
    {
        var id = await SeedLocalAnimeAsync();

        var resp = await _client.GetAsync($"/api/animes/details?source=local&id={id}",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<DetailsDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Source.Should().Be("local");
        payload.Id.Should().Be(id);
        payload.Title.Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task Details_AniList_DeveTrazerLinks_E_StreamingEpisodes()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=AniList&externalId=123",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<DetailsDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Source.Should().Be("AniList");
        payload.ExternalLinks.Should().NotBeNull();
        payload.ExternalLinks.Should().NotBeEmpty();
        payload.StreamingEpisodes.Should().NotBeNull();
        payload.StreamingEpisodes.Should().NotBeEmpty();
        payload.Genres.Should().NotBeNullOrEmpty();
        payload.Genres.Should().Contain("Action");
    }

    [Fact]
    public async Task Details_Jikan_DeveRetornar200()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=Jikan&externalId=5114",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<DetailsDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Source.Should().Be("Jikan");
        payload.ExternalId.Should().Be("5114");
        payload.Title.Should().NotBeNullOrWhiteSpace();
        payload.Genres.Should().NotBeNullOrEmpty();
        payload.Genres.Should().Contain("Action");
    }

    [Fact]
    public async Task Details_Kitsu_DeveRetornar200()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=Kitsu&externalId=kitsu-1",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<DetailsDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Source.Should().Be("Kitsu");
        payload.ExternalId.Should().Be("kitsu-1");
        payload.Title.Should().NotBeNullOrWhiteSpace();
        payload.Genres.Should().NotBeNullOrEmpty();
        payload.Genres.Should().Contain("Sci-Fi");
    }

    [Fact]
    public async Task Details_Local_SemId_DeveRetornar400_ProblemDetails_ComErroId()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=local",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.GetProperty("title").GetString().Should().NotBeNullOrWhiteSpace();

        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();
        errors.ValueKind.Should().Be(JsonValueKind.Object);

        // FluentValidationActionFilter geralmente usa o nome da propriedade ("Id")
        errors.TryGetProperty("Id", out var idErrors).Should().BeTrue();
        idErrors.ValueKind.Should().Be(JsonValueKind.Array);
        idErrors.GetArrayLength().Should().BeGreaterThan(0);

        //CustomizeProblemDetails injeta traceId
        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Details_Local_IdInexistente_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=local&id=999999",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Details_AniList_ExternalIdInvalido_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=AniList&externalId=abc",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Details_AniList_ExternalIdInexistente_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=AniList&externalId=999999",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Details_Jikan_ExternalIdInvalido_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=Jikan&externalId=abc",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Details_Jikan_ExternalIdInexistente_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=Jikan&externalId=999999",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Details_Kitsu_ExternalIdInexistente_DeveRetornar404()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=Kitsu&externalId=does-not-exist",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // ---------- helpers ----------
    private async Task<int> SeedLocalAnimeAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        db.Animes.Add(new AnimeHub.Domain.Entities.Anime
        {
            Title = "Local Anime",
            Synopsis = "Local desc",
            Year = 2020,
            Score = 9.1m,
            CoverUrl = null,
            CreatedAtUtc = DateTime.UtcNow
        });

        await db.SaveChangesAsync(TestContext.Current.CancellationToken);
        return db.Animes.OrderByDescending(x => x.Id).Select(x => x.Id).First();
    }

    private sealed class DetailsDto
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

        [JsonPropertyName("externalLinks")]
        public List<LinkDto> ExternalLinks { get; set; } = new();

        [JsonPropertyName("streamingEpisodes")]
        public List<EpisodeDto> StreamingEpisodes { get; set; } = new();
    }

    private sealed class LinkDto
    {
        [JsonPropertyName("site")]
        public string Site { get; set; } = string.Empty;

        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;
    }

    private sealed class EpisodeDto
    {
        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;

        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        [JsonPropertyName("site")]
        public string? Site { get; set; }
    }
}