using AnimeHub.Domain.Entities;

namespace AnimeHub.Domain.Interfaces;

public interface IUserAnimeRepository
{
    Task<UserAnime?> GetByIdAsync(int id, int userId, CancellationToken ct);
    Task<(List<UserAnime> Items, int TotalCount)> GetByUserAsync(int userId, string? status, int? year, int page, int pageSize, CancellationToken ct);
    Task<bool> ExistsAsync(int userId, string? externalProvider, string? externalId, CancellationToken ct);
    Task<UserAnime> AddAsync(UserAnime entity, CancellationToken ct);
    Task UpdateAsync(UserAnime entity, CancellationToken ct);
    Task<bool> DeleteAsync(int id, int userId, CancellationToken ct);
}
