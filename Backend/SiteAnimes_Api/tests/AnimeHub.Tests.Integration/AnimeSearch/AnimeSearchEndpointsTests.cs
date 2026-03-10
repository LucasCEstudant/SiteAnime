using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AnimeHub.Tests.Integration.AnimeSearch;

public class AnimeSearchEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public AnimeSearchEndpointsTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Search_DeveAgregar_Local_E_ProvidersExternos()
    {
        // Arrange
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon Ball", 1986),
            new AnimeSeed("Dr. Stone", 2019)
        });

        // Act
        var response = await _client.GetAsync("/api/animes/search?q=dra&limit=10",
            TestContext.Current.CancellationToken);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await response.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        // Local + providers fakes (Jikan/AniList/Kitsu)
        payload.Items.Should().Contain(x => x.Source == "local");
        payload.Items.Should().Contain(x => x.Source == "Jikan");
        payload.Items.Should().Contain(x => x.Source == "AniList");
        payload.Items.Should().Contain(x => x.Source == "Kitsu");

        // Providers externos devem retornar gêneros
        var extItems = payload.Items.Where(x => x.Source != "local").ToList();
        extItems.Should().OnlyContain(x => x.Genres != null && x.Genres.Count > 0);

        // Local (sem gênero no DB) retorna lista vazia
        payload.Items.Where(x => x.Source == "local")
            .Should().OnlyContain(x => x.Genres != null && x.Genres.Count == 0);
    }

    [Fact]
    public async Task Search_KeysetCursor_NaoDeveRepetirItensLocaisEntrePaginas()
    {
        // Arrange
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon A", 2001),
            new AnimeSeed("Dragon B", 2002),
            new AnimeSeed("Dragon C", 2003)
        });

        // 1a página
        var resp1 = await _client.GetAsync("/api/animes/search?q=dra&limit=2",
            TestContext.Current.CancellationToken);

        resp1.StatusCode.Should().Be(HttpStatusCode.OK);

        var page1 = await resp1.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        page1.Should().NotBeNull();
        page1!.Items.Should().NotBeEmpty();
        page1.NextCursor.Should().NotBeNullOrWhiteSpace();

        var page1LocalIds = page1.Items.Where(x => x.Source == "local" && x.Id.HasValue)
            .Select(x => x.Id!.Value)
            .ToHashSet();

        // 2a página (com cursor)
        var resp2 = await _client.GetAsync($"/api/animes/search?q=dra&limit=2&cursor={page1.NextCursor}",
            TestContext.Current.CancellationToken);

        resp2.StatusCode.Should().Be(HttpStatusCode.OK);

        var page2 = await resp2.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        page2.Should().NotBeNull();

        var page2LocalIds = page2!.Items.Where(x => x.Source == "local" && x.Id.HasValue)
            .Select(x => x.Id!.Value)
            .ToHashSet();

        // Assert: local não repete
        page2LocalIds.Overlaps(page1LocalIds).Should().BeFalse();

        // Assert: total local retornado >= 3 (pode vir junto com externos)
        var totalLocal = page1.Items.Count(x => x.Source == "local")
                      + page2.Items.Count(x => x.Source == "local");

        totalLocal.Should().BeGreaterThanOrEqualTo(3);
    }

    [Fact]
    public async Task Search_DeveRetornarProvidersExternos_EmPaginasSequenciais()
    {
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon A", 2001),
            new AnimeSeed("Dragon B", 2002)
        });

        var resp1 = await _client.GetAsync("/api/animes/search?q=dra&limit=2", TestContext.Current.CancellationToken);
        resp1.StatusCode.Should().Be(HttpStatusCode.OK);

        var page1 = await resp1.Content.ReadFromJsonAsync<SearchResponseDto>(cancellationToken: TestContext.Current.CancellationToken);
        page1!.Items.Should().Contain(x => x.Source == "Kitsu");
        page1.NextCursor.Should().NotBeNullOrWhiteSpace();

        var resp2 = await _client.GetAsync($"/api/animes/search?q=dra&limit=2&cursor={page1.NextCursor}", TestContext.Current.CancellationToken);
        resp2.StatusCode.Should().Be(HttpStatusCode.OK);

        var page2 = await resp2.Content.ReadFromJsonAsync<SearchResponseDto>(cancellationToken: TestContext.Current.CancellationToken);
        page2!.Items.Should().Contain(x => x.Source == "Kitsu");
    }

    // ---------------- NEGATIVOS ----------------

    [Fact]
    public async Task Search_QVazio_DeveRetornar400()
    {
        // q vazio normalmente invalida (string non-null + ApiController) => 400
        var resp = await _client.GetAsync("/api/animes/search?q=&limit=12",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Search_SemParametroQ_DeveRetornar400()
    {
        // q ausente normalmente invalida (ApiController) => 400
        var resp = await _client.GetAsync("/api/animes/search?limit=12",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Search_CursorInvalido_NaoDeveQuebrar_DeveRetornar200()
    {
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon Ball", 1986),
            new AnimeSeed("Dr. Stone", 2019)
        });

        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=10&cursor=CURSOR_LIXO@@@",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeNull();
        payload.Items.Should().NotBeEmpty(); // local + fakes
    }

    [Fact]
    public async Task Search_LimitMuitoAlto_DeveRetornar400_ProblemDetails_ComErroLimit()
    {
        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=999",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();

        errors.TryGetProperty("Limit", out var limitErrors).Should().BeTrue();
        limitErrors.ValueKind.Should().Be(JsonValueKind.Array);
        limitErrors.GetArrayLength().Should().BeGreaterThan(0);

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Search_LimitZero_DeveRetornar400_ProblemDetails_ComErroLimit()
    {
        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=0",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();

        errors.TryGetProperty("Limit", out var limitErrors).Should().BeTrue();
        limitErrors.ValueKind.Should().Be(JsonValueKind.Array);
        limitErrors.GetArrayLength().Should().BeGreaterThan(0);

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Search_NaoDeveRetornar500_QuandoNaoExistemResultadosLocais()
    {
        await ResetAnimesAsync();

        var resp = await _client.GetAsync("/api/animes/search?q=zzzz&limit=10",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeNull();

        // Pode vir apenas externo (fake providers) mesmo sem local
        payload.Items.Should().Contain(x => x.Source == "Jikan");
        payload.Items.Should().Contain(x => x.Source == "AniList");
        payload.Items.Should().Contain(x => x.Source == "Kitsu");

        payload.Items.Should().NotContain(x => x.Source == "local");
    }

    // ============================================================
    // Filtro por gênero
    // ============================================================

    [Fact]
    public async Task Search_ComGenero_DeveRetornarApenasExternosComGeneroCorrespondente()
    {
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon Ball", 1986)
        });

        // FakeProvider retorna Genres: ["Action", "Adventure"]
        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=10&genres=Action",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        // Com filtro de gênero ativo, itens locais são excluídos
        payload.Items.Should().NotContain(x => x.Source == "local");

        // Todos os itens devem conter o gênero filtrado
        payload.Items.Should().OnlyContain(x => x.Genres.Contains("Action"));
    }

    [Fact]
    public async Task Search_ComMultiplosGeneros_DeveFiltrarPorOR()
    {
        await ResetAnimesAsync();

        // FakeProvider retorna Genres: ["Action", "Adventure"]
        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=10&genres=Action&genres=Fantasy",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().NotBeEmpty();

        // OR: pelo menos um dos gêneros deve estar presente
        payload.Items.Should().OnlyContain(x =>
            x.Genres.Any(g => g == "Action" || g == "Adventure" || g == "Fantasy"));
    }

    [Fact]
    public async Task Search_SemGenero_DeveRetornarLocalEExterno()
    {
        await ResetAnimesAsync();

        await SeedAnimesAsync(new[]
        {
            new AnimeSeed("Dragon Ball", 1986)
        });

        // Sem parâmetro Genres — comportamento original
        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=10",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        payload!.Items.Should().Contain(x => x.Source == "local");
        payload.Items.Should().Contain(x => x.Source != "local");
    }

    [Fact]
    public async Task Search_GeneroInexistente_DeveRetornarVazio()
    {
        await ResetAnimesAsync();

        var resp = await _client.GetAsync("/api/animes/search?q=dra&limit=10&genres=GeneroQueNaoExiste",
            TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var payload = await resp.Content.ReadFromJsonAsync<SearchResponseDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        payload.Should().NotBeNull();
        // Nenhum item deve ter esse gênero
        payload!.Items.Should().BeEmpty();
    }

    // ---------- helpers ----------

    private async Task ResetAnimesAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Limpa somente tabela Animes (mantém Users/RefreshTokens, etc.)
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

    private sealed class SearchResponseDto
    {
        [JsonPropertyName("items")]
        public List<SearchItemDto> Items { get; set; } = new();

        [JsonPropertyName("nextCursor")]
        public string? NextCursor { get; set; }
    }

    private sealed class SearchItemDto
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
