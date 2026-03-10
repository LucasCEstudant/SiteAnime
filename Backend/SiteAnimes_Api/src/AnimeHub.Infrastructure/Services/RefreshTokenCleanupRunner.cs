using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Infrastructure.Services;

public sealed class RefreshTokenCleanupRunner
{
    private readonly AppDbContext _db;

    public RefreshTokenCleanupRunner(AppDbContext db) => _db = db;

    public async Task<int> CleanupAsync(int revokeRetentionDays, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var revokedCutoff = now.AddDays(-revokeRetentionDays);

        var tokens = await _db.RefreshTokens
            .Where(x => x.ExpiresAtUtc <= now || (x.RevokedAtUtc != null && x.RevokedAtUtc <= revokedCutoff))
            .ToListAsync(ct);

        if (tokens.Count == 0) return 0;

        _db.RefreshTokens.RemoveRange(tokens);
        await _db.SaveChangesAsync(ct);

        return tokens.Count;
    }
}