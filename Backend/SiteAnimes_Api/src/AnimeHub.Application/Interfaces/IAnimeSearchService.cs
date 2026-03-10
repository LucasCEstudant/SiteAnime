using AnimeHub.Application.Dtos.Search;

namespace AnimeHub.Application.Interfaces
{
    public interface IAnimeSearchService
    {
        Task<SearchAnimeResponseDto> SearchAsync(string q, int limit, string? cursor, int? year, IReadOnlyList<string>? genres, CancellationToken ct);
    }
}
