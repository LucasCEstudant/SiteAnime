using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace AnimeHub.Tests.Integration.HomeBanners;

public class HomeBannersEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public HomeBannersEndpointsTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    // ============================================================
    // GET /api/home/banners (público)
    // ============================================================

    [Fact]
    public async Task GetBanners_DeveRetornar200_ListaVazia_QuandoNenhumConfigurado()
    {
        await ResetBannersAsync();

        var resp = await _client.GetAsync("/api/home/banners", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var banners = await resp.Content.ReadFromJsonAsync<List<BannerDto>>(
            cancellationToken: TestContext.Current.CancellationToken);

        banners.Should().NotBeNull();
        banners!.Should().BeEmpty();
    }

    [Fact]
    public async Task GetBanners_DeveRetornarBannersConfigurados()
    {
        await ResetBannersAsync();
        await AuthorizeAsAdminAsync();

        // Configura banner com anime local
        await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            animeId = 1
        }, TestContext.Current.CancellationToken);

        // Remove auth para testar GET público
        _client.DefaultRequestHeaders.Authorization = null;

        var resp = await _client.GetAsync("/api/home/banners", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var banners = await resp.Content.ReadFromJsonAsync<List<BannerDto>>(
            cancellationToken: TestContext.Current.CancellationToken);

        banners.Should().NotBeNull();
        banners!.Should().ContainSingle(b => b.Slot == "home-primary");
    }

    // ============================================================
    // PUT /api/home/banners/{slot} (admin)
    // ============================================================

    [Fact]
    public async Task PutBanner_DeveRetornar401_SemToken()
    {
        _client.DefaultRequestHeaders.Authorization = null;

        var resp = await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            animeId = 1
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task PutBanner_AnimeLocal_DeveConfigurarCorretamente()
    {
        await ResetBannersAsync();
        await SeedAnimeAsync();
        await AuthorizeAsAdminAsync();

        var resp = await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            animeId = await GetFirstAnimeIdAsync()
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var banner = await resp.Content.ReadFromJsonAsync<BannerDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        banner.Should().NotBeNull();
        banner!.Slot.Should().Be("home-primary");
        banner.AnimeId.Should().NotBeNull();
        banner.ExternalId.Should().BeNull();
        banner.ExternalProvider.Should().BeNull();
    }

    [Fact]
    public async Task PutBanner_AnimeExterno_DeveConfigurarCorretamente()
    {
        await ResetBannersAsync();
        await AuthorizeAsAdminAsync();

        var resp = await _client.PutAsJsonAsync("/api/home/banners/home-secondary", new
        {
            externalId = "12345",
            externalProvider = "AniList"
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var banner = await resp.Content.ReadFromJsonAsync<BannerDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        banner.Should().NotBeNull();
        banner!.Slot.Should().Be("home-secondary");
        banner.AnimeId.Should().BeNull();
        banner.ExternalId.Should().Be("12345");
        banner.ExternalProvider.Should().Be("AniList");
    }

    [Fact]
    public async Task PutBanner_SlotInvalido_DeveRetornar400()
    {
        await AuthorizeAsAdminAsync();

        var resp = await _client.PutAsJsonAsync("/api/home/banners/invalid-slot", new
        {
            animeId = 1
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task PutBanner_DeveSubstituirConfigAnterior()
    {
        await ResetBannersAsync();
        await AuthorizeAsAdminAsync();

        // Primeiro: anime local
        await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            animeId = 1
        }, TestContext.Current.CancellationToken);

        // Segundo: troca para externo
        var resp = await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            externalId = "999",
            externalProvider = "Jikan"
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var banner = await resp.Content.ReadFromJsonAsync<BannerDto>(
            cancellationToken: TestContext.Current.CancellationToken);

        banner!.AnimeId.Should().BeNull();
        banner.ExternalId.Should().Be("999");
        banner.ExternalProvider.Should().Be("Jikan");
    }

    [Fact]
    public async Task PutBanner_DoisSlots_DeveManterAmbos()
    {
        await ResetBannersAsync();
        await AuthorizeAsAdminAsync();

        await _client.PutAsJsonAsync("/api/home/banners/home-primary", new
        {
            animeId = 1
        }, TestContext.Current.CancellationToken);

        await _client.PutAsJsonAsync("/api/home/banners/home-secondary", new
        {
            externalId = "abc",
            externalProvider = "Kitsu"
        }, TestContext.Current.CancellationToken);

        _client.DefaultRequestHeaders.Authorization = null;
        var resp = await _client.GetAsync("/api/home/banners", TestContext.Current.CancellationToken);

        var banners = await resp.Content.ReadFromJsonAsync<List<BannerDto>>(
            cancellationToken: TestContext.Current.CancellationToken);

        banners.Should().HaveCount(2);
        banners.Should().Contain(b => b.Slot == "home-primary");
        banners.Should().Contain(b => b.Slot == "home-secondary");
    }

    // ---------- helpers ----------

    private async Task ResetBannersAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.ExecuteSqlRawAsync("DELETE FROM HomeBanners;", TestContext.Current.CancellationToken);
    }

    private async Task SeedAnimeAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        if (!await db.Animes.AnyAsync(TestContext.Current.CancellationToken))
        {
            db.Animes.Add(new AnimeHub.Domain.Entities.Anime
            {
                Title = "Banner Anime",
                Year = 2024,
                CreatedAtUtc = DateTime.UtcNow
            });
            await db.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
    }

    private async Task<int> GetFirstAnimeIdAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var anime = await db.Animes.FirstAsync(TestContext.Current.CancellationToken);
        return anime.Id;
    }

    private async Task AuthorizeAsAdminAsync()
    {
        var (token, _) = await _factory.AuthenticateAdminAsync(_client, TestContext.Current.CancellationToken);
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    private sealed class BannerDto
    {
        [JsonPropertyName("slot")]
        public string Slot { get; set; } = string.Empty;

        [JsonPropertyName("animeId")]
        public int? AnimeId { get; set; }

        [JsonPropertyName("externalId")]
        public string? ExternalId { get; set; }

        [JsonPropertyName("externalProvider")]
        public string? ExternalProvider { get; set; }
    }
}
