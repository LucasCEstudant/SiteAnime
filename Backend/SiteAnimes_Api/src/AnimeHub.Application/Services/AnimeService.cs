using AnimeHub.Application.Dtos.Anime;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;

namespace AnimeHub.Application.Services
{
    public class AnimeService : IAnimeService
    {
        private readonly IAnimeRepository _repo;
        public AnimeService(IAnimeRepository repo) => _repo = repo;

        public Task<List<Anime>> GetAllAsync(CancellationToken ct) => _repo.GetAllAsync(ct);

        public async Task<Anime?> GetByIdAsync(int id, CancellationToken ct)
        {
            var anime = await _repo.GetByIdAsync(id, ct);
            return anime;
        }

        public async Task<Anime> CreateAsync(AnimeCreateDto dto, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(dto.Title))
                throw new ArgumentException("Title é obrigatório.");

            var entity = new Anime
            {
                Title = dto.Title.Trim(),
                Synopsis = dto.Synopsis,
                Year = dto.Year,
                Status = dto.Status,
                Score = dto.Score,
                CoverUrl = dto.CoverUrl
            };

            entity.CreatedAtUtc = DateTime.UtcNow;

            return await _repo.AddAsync(entity, ct);
        }

        public async Task<bool> UpdateAsync(int id, AnimeUpdateDto dto, CancellationToken ct)
        {
            var entity = await _repo.GetByIdAsync(id, ct);
            if (entity is null) return false;

            entity.Title = dto.Title.Trim();
            entity.Synopsis = dto.Synopsis;
            entity.Year = dto.Year;
            entity.Status = dto.Status;
            entity.Score = dto.Score;
            entity.CoverUrl = dto.CoverUrl;
            entity.UpdatedAtUtc = DateTime.UtcNow;

            await _repo.UpdateAsync(entity, ct);
            return true;
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken ct)
        {
            var entity = await _repo.GetByIdAsync(id, ct);
            if (entity is null) return false;

            await _repo.DeleteAsync(entity, ct);
            return true;
        }
    }
}
