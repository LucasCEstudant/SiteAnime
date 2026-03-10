namespace AnimeHub.Application.Dtos.Search
{
    public record SearchAnimeItemDto(
        string Source,       // "local" (no futuro: "jikan", "anilist", "kitsu"...)
        int? Id,             // local
        string? ExternalId,  // externo
        string Title,
        int? Year,
        decimal? Score,
        string? CoverUrl,
        IReadOnlyList<string> Genres
    );
}
