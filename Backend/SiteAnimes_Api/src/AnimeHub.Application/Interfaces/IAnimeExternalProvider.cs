using AnimeHub.Application.Dtos.External;

namespace AnimeHub.Application.Interfaces
{
    public interface IAnimeExternalProvider
    {
        string Provider { get; } // "Jikan", "AniList", "Kitsu", "Shikimori"

        Task<List<ExternalAnimeDto>> SearchAsync(string q, int pageOrOffset, int limit, CancellationToken ct);

        Task<ExternalAnimeDto?> GetByIdAsync(string externalId, CancellationToken ct);
    }
}
