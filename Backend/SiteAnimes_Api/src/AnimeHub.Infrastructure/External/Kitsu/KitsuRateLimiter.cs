using System.Threading.RateLimiting;

namespace AnimeHub.Infrastructure.External.Kitsu
{
    public sealed class KitsuRateLimiter
    {
        private readonly RateLimiter _perSecond = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
        {
            TokenLimit = 3,
            TokensPerPeriod = 3,
            ReplenishmentPeriod = TimeSpan.FromSeconds(1),
            QueueLimit = 0,
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            AutoReplenishment = true
        });

        private readonly RateLimiter _perMinute = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
        {
            TokenLimit = 60,
            TokensPerPeriod = 60,
            ReplenishmentPeriod = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
            AutoReplenishment = true
        });

        public async ValueTask<bool> TryAcquireAsync(CancellationToken ct)
        {
            using var a = await _perSecond.AcquireAsync(1, ct);
            if (!a.IsAcquired) return false;

            using var b = await _perMinute.AcquireAsync(1, ct);
            return b.IsAcquired;
        }
    }
}
