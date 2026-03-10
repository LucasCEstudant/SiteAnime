using AnimeHub.Infrastructure.External.AniList.Models;
using AnimeHub.Infrastructure.External.AniList.Queries;
using AnimeHub.Infrastructure.External.Common;

namespace AnimeHub.Infrastructure.External.AniList;

public sealed class AniListClient
{
    private readonly GraphQlClient _gql;

    public AniListClient(GraphQlClient gql) => _gql = gql;

    public Task<AniListSearchResponse?> SearchAsync(string q, int page, int perPage, CancellationToken ct)
        => _gql.PostAsync<AniListSearchResponse>(
            AniListQueries.Search,
            AniListQueryRequests.SearchVars(q, page, perPage),
            ct);

    public async Task<List<string>> GetGenresAsync(CancellationToken ct)
    {
        var payload = await _gql.PostAsync<AniListGenresResponse>(
            AniListQueries.GenreCollection,
            new { },
            ct);

        return payload?.Data?.GenreCollection ?? new List<string>();
    }

    public Task<AniListSearchResponse?> SearchByGenreAsync(string genre, int page, int perPage, CancellationToken ct)
        => _gql.PostAsync<AniListSearchResponse>(
            AniListQueries.SearchByGenre,
            AniListQueryRequests.ByGenreVars(genre, page, perPage),
            ct);

    public Task<AniListSearchResponse?> SearchByYearAsync(int year, int page, int perPage, CancellationToken ct)
        => _gql.PostAsync<AniListSearchResponse>(
            AniListQueries.SearchByYear,
            AniListQueryRequests.ByYearVars(year, page, perPage),
            ct);

    public Task<AniListSearchResponse?> SearchBySeasonAsync(string season, int seasonYear, int page, int perPage, CancellationToken ct)
        => _gql.PostAsync<AniListSearchResponse>(
            AniListQueries.SearchBySeason,
            AniListQueryRequests.BySeasonVars(season, seasonYear, page, perPage),
            ct);

    public Task<AniListMediaByIdResponse?> GetByIdAsync(int id, CancellationToken ct)
        => _gql.PostAsync<AniListMediaByIdResponse>(
            AniListQueries.DetailsById,
            AniListQueryRequests.ByIdVars(id),
            ct);
}