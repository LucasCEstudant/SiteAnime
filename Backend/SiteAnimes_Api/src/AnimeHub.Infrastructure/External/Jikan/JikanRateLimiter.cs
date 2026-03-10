using System.Threading.RateLimiting;

namespace AnimeHub.Infrastructure.External.Jikan
{
    public sealed class JikanRateLimiter
    {
        private readonly RateLimiter _perSecond;
        private readonly RateLimiter _perMinute;

        public JikanRateLimiter()
        {
            _perSecond = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
            {
                TokenLimit = 3,
                TokensPerPeriod = 3,
                ReplenishmentPeriod = TimeSpan.FromSeconds(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0, // não enfileira (autocomplete precisa responder rápido)
                AutoReplenishment = true
            });

            _perMinute = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
            {
                TokenLimit = 60,
                TokensPerPeriod = 60,
                ReplenishmentPeriod = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                AutoReplenishment = true
            });
        }

        public async ValueTask<bool> TryAcquireAsync(CancellationToken ct)
        {
            using var leaseSecond = await _perSecond.AcquireAsync(1, ct);
            if (!leaseSecond.IsAcquired) return false;

            using var leaseMinute = await _perMinute.AcquireAsync(1, ct);
            if (!leaseMinute.IsAcquired) return false;

            return true;
        }
    }
}
