using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Infrastructure.Repositories;

public class UserAnimeRepository : IUserAnimeRepository
{
    private readonly AppDbContext _db;
    public UserAnimeRepository(AppDbContext db) => _db = db;

    public Task<UserAnime?> GetByIdAsync(int id, int userId, CancellationToken ct)
        => _db.UserAnimes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct);

    public async Task<(List<UserAnime> Items, int TotalCount)> GetByUserAsync(
        int userId, string? status, int? year, int page, int pageSize, CancellationToken ct)
    {
        var query = _db.UserAnimes
            .AsNoTracking()
            .Where(x => x.UserId == userId);

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(x => x.Status == status);

        if (year.HasValue)
            query = query.Where(x => x.Year == year.Value);

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(x => x.UpdatedAtUtc ?? x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, total);
    }

    public Task<bool> ExistsAsync(int userId, string? externalProvider, string? externalId, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(externalProvider) || string.IsNullOrWhiteSpace(externalId))
            return Task.FromResult(false);

        return _db.UserAnimes.AnyAsync(
            x => x.UserId == userId
              && x.ExternalProvider == externalProvider
              && x.ExternalId == externalId, ct);
    }

    public async Task<UserAnime> AddAsync(UserAnime entity, CancellationToken ct)
    {
        _db.UserAnimes.Add(entity);
        await _db.SaveChangesAsync(ct);
        return entity;
    }

    public async Task UpdateAsync(UserAnime entity, CancellationToken ct)
    {
        _db.UserAnimes.Update(entity);
        await _db.SaveChangesAsync(ct);
    }

    public async Task<bool> DeleteAsync(int id, int userId, CancellationToken ct)
    {
        var entity = await _db.UserAnimes
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct);

        if (entity is null) return false;

        _db.UserAnimes.Remove(entity);
        await _db.SaveChangesAsync(ct);
        return true;
    }
}
