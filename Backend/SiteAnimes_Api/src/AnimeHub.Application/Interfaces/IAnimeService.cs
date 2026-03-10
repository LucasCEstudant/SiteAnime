using AnimeHub.Application.Dtos.Anime;
using AnimeHub.Domain.Entities;

namespace AnimeHub.Application.Interfaces
{
    public interface IAnimeService
    {
        Task<List<Anime>> GetAllAsync(CancellationToken ct);
        Task<Anime?> GetByIdAsync(int id, CancellationToken ct);
        Task<Anime> CreateAsync(AnimeCreateDto dto, CancellationToken ct);
        Task<bool> UpdateAsync(int id, AnimeUpdateDto dto, CancellationToken ct);
        Task<bool> DeleteAsync(int id, CancellationToken ct);
    }
}
