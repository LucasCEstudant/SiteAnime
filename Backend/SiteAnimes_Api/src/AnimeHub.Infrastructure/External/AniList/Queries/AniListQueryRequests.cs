namespace AnimeHub.Infrastructure.External.AniList.Queries;

public static class AniListQueryRequests
{
    public static object SearchVars(string q, int page, int perPage) => new { search = q, page, perPage };
    public static object ByGenreVars(string genre, int page, int perPage) => new { genre = new[] { genre }, page, perPage };
    public static object ByYearVars(int year, int page, int perPage) => new { year, page, perPage };
    public static object BySeasonVars(string season, int seasonYear, int page, int perPage) => new { season, year = seasonYear, page, perPage };
    public static object ByIdVars(int id) => new { id };
}