using AnimeHub.Application.Dtos.Filters;

namespace AnimeHub.Application.Interfaces
{
    public interface IAnimeFiltersService
    {
        Task<FilterAnimeResponseDto> ByGenreAsync(string genre, int limit, string? cursor, CancellationToken ct);
        Task<FilterAnimeResponseDto> ByYearAsync(int year, int limit, string? cursor, CancellationToken ct);
        Task<FilterAnimeResponseDto> SeasonNowAsync(int limit, string? cursor, CancellationToken ct);
    }
}
