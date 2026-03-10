using System.Net;
using System.Net.Http.Json;
using AnimeHub.Infrastructure.External.Kitsu.Models;
using AnimeHub.Infrastructure.External.Kitsu.Queries;

namespace AnimeHub.Infrastructure.External.Kitsu;

public sealed class KitsuClient
{
    private readonly HttpClient _http;
    public KitsuClient(HttpClient http) => _http = http;

    public Task<KitsuAnimeSearchResponse?> SearchAsync(string q, int offset, int limit, CancellationToken ct)
        => _http.GetFromJsonAsync<KitsuAnimeSearchResponse>(KitsuQueryRequests.SearchByText(q, offset, limit), ct);

    public Task<KitsuAnimeSearchResponse?> SearchByCategoryAsync(string categorySlug, int offset, int limit, CancellationToken ct)
        => _http.GetFromJsonAsync<KitsuAnimeSearchResponse>(KitsuQueryRequests.SearchByCategory(categorySlug, offset, limit), ct);

    public async Task<KitsuAnimeByIdResponse?> GetByIdAsync(string id, CancellationToken ct)
    {
        using var resp = await _http.GetAsync(KitsuQueryRequests.GetById(id), ct);

        if (resp.StatusCode == HttpStatusCode.NotFound)
            return null;

        resp.EnsureSuccessStatusCode();
        return await resp.Content.ReadFromJsonAsync<KitsuAnimeByIdResponse>(cancellationToken: ct);
    }
}