using AnimeHub.Domain.Entities;

namespace AnimeHub.Domain.Interfaces
{
    public interface IAnimeRepository
    {
        Task<List<Anime>> GetAllAsync(CancellationToken ct);
        Task<Anime?> GetByIdAsync(int id, CancellationToken ct);
        Task<Anime> AddAsync(Anime anime, CancellationToken ct);
        Task UpdateAsync(Anime anime, CancellationToken ct);
        Task DeleteAsync(Anime anime, CancellationToken ct);
    }
}
