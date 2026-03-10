namespace AnimeHub.Application.Dtos.Anime
{
    public record AnimeUpdateDto(
        string Title,
        string? Synopsis,
        int? Year,
        string? Status,
        decimal? Score,
        string? CoverUrl
    );
}
