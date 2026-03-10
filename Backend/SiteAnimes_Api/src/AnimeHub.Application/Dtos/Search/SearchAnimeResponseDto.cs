
namespace AnimeHub.Application.Dtos.Search
{
    public record SearchAnimeResponseDto(
        IReadOnlyList<SearchAnimeItemDto> Items,
        string? NextCursor
    );
}
