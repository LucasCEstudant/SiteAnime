using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Infrastructure.Repositories
{
    public class AnimeRepository : IAnimeRepository
    {
        private readonly AppDbContext _db;
        public AnimeRepository(AppDbContext db) => _db = db;

        public async Task<List<Anime>> GetAllAsync(CancellationToken ct)
            => await _db.Animes.AsNoTracking().OrderByDescending(x => x.Id).ToListAsync(ct);

        public async Task<Anime?> GetByIdAsync(int id, CancellationToken ct)
            => await _db.Animes.FirstOrDefaultAsync(x => x.Id == id, ct);

        public async Task<Anime> AddAsync(Anime anime, CancellationToken ct)
        {
            _db.Animes.Add(anime);
            await _db.SaveChangesAsync(ct);
            return anime;
        }

        public async Task UpdateAsync(Anime anime, CancellationToken ct)
            => await _db.SaveChangesAsync(ct);

        public async Task DeleteAsync(Anime anime, CancellationToken ct)
        {
            _db.Animes.Remove(anime);
            await _db.SaveChangesAsync(ct);
        }
    }
}
