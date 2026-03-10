using System.Threading.RateLimiting;

namespace AnimeHub.Infrastructure.External.AniList
{
    public sealed class AniListRateLimiter
    {
        private readonly RateLimiter _perMinute = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
        {
            TokenLimit = 90,
            TokensPerPeriod = 90,
            ReplenishmentPeriod = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            AutoReplenishment = true
        });

        public async ValueTask<bool> TryAcquireAsync(CancellationToken ct)
        {
            using var lease = await _perMinute.AcquireAsync(1, ct);
            return lease.IsAcquired;
        }
    }
}
