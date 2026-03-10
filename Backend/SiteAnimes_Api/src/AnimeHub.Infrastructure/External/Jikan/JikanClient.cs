using AnimeHub.Infrastructure.External.Common;
using AnimeHub.Infrastructure.External.Jikan.Models;

namespace AnimeHub.Infrastructure.External.Jikan;

public sealed class JikanClient
{
    private readonly RestJsonClient _rest;

    public JikanClient(RestJsonClient rest) => _rest = rest;

    public Task<JikanSearchResponse?> SearchAsync(string q, int page, int limit, CancellationToken ct)
        => _rest.GetAsync<JikanSearchResponse>(
            $"anime?q={Uri.EscapeDataString(q)}&page={page}&limit={limit}", ct);

    public Task<JikanByIdResponse?> GetByIdAsync(int malId, CancellationToken ct)
        => _rest.GetAsync<JikanByIdResponse>($"anime/{malId}/full", ct, treatNotFoundAsNull: true);

    public Task<JikanSearchResponse?> SeasonNowAsync(int page, int limit, CancellationToken ct)
        => _rest.GetAsync<JikanSearchResponse>($"seasons/now?page={page}&limit={limit}", ct);

    public Task<object?> GenresAnimeAsync(CancellationToken ct)
        => _rest.GetAsync<object>("genres/anime", ct);
}