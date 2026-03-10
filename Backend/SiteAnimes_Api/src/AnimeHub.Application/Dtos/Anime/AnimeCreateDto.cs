namespace AnimeHub.Application.Dtos.Anime
{
    public record AnimeCreateDto(
        string Title,
        string? Synopsis,
        int? Year,
        string? Status,
        decimal? Score,
        string? CoverUrl
    );
}
