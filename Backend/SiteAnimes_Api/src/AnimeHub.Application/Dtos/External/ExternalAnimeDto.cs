namespace AnimeHub.Application.Dtos.External
{
    public record ExternalAnimeDto(
        string Provider,
        string ExternalId,
        string Title,
        string? Synopsis,
        int? Year,
        decimal? Score,
        string? CoverUrl,
        IReadOnlyList<string> Genres
    );
}
