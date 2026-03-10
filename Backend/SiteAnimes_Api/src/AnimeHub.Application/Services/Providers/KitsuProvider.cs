using System.Globalization;
using AnimeHub.Application.Dtos.External;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.Kitsu;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services.Providers
{
    public sealed class KitsuProvider : IAnimeExternalProvider
    {
        public string Provider => "Kitsu";

        private readonly KitsuClient _client;
        private readonly IMemoryCache _cache;
        private readonly KitsuRateLimiter _limiter;
        private readonly ILogger<KitsuProvider> _logger;

        public KitsuProvider(KitsuClient client, IMemoryCache cache, KitsuRateLimiter limiter, ILogger<KitsuProvider> logger)
        {
            _client = client;
            _cache = cache;
            _limiter = limiter;
            _logger = logger;
        }

        public async Task<List<ExternalAnimeDto>> SearchAsync(string q, int offset, int limit, CancellationToken ct)
        {
            q = (q ?? "").Trim();
            if (q.Length == 0) return new();

            // Kitsu max 20
            limit = Math.Clamp(limit, 1, 20);
            offset = Math.Max(0, offset);

            var normQ = q.ToLowerInvariant();
            var cacheKey = $"kitsu:search:q={normQ}:o={offset}:l={limit}";

            if (_cache.TryGetValue(cacheKey, out List<ExternalAnimeDto>? cached) && cached is not null)
                return cached;

            if (!await _limiter.TryAcquireAsync(ct))
            {
                _logger.LogWarning("Kitsu rate limited. QLen={Len} Offset={Offset}", normQ.Length, offset);
                return new();
            }

            try
            {
                var res = await _client.SearchAsync(q, offset, limit, ct);
                var data = res?.Data ?? new();
                var included = res?.Included;

                var mapped = data.Select(d =>
                {
                    var a = d.Attributes;

                    // averageRating vem string tipo "82.28" (0..100).
                    decimal? score10 = null;
                    if (a?.AverageRating is not null &&
                        decimal.TryParse(a.AverageRating, NumberStyles.Any, CultureInfo.InvariantCulture, out var r))
                    {
                        score10 = Math.Round(r / 10m, 2);
                    }

                    int? year = null;
                    if (a?.StartDate is not null && a.StartDate.Length >= 4 &&
                        int.TryParse(a.StartDate.Substring(0, 4), out var y))
                    {
                        year = y;
                    }

                    return new ExternalAnimeDto(
                        Provider: Provider,
                        ExternalId: d.Id ?? "",
                        Title: a?.CanonicalTitle ?? "Unknown",
                        Synopsis: a?.Synopsis,
                        Year: year,
                        Score: score10,
                        CoverUrl: a?.PosterImage?.Large,
                        Genres: KitsuCategoryHelper.ExtractCategories(d, included)
                    );
                })
                .Where(x => !string.IsNullOrWhiteSpace(x.ExternalId) && !string.IsNullOrWhiteSpace(x.Title))
                .ToList();

                _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
                {
                    SlidingExpiration = TimeSpan.FromSeconds(15),
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
                });

                return mapped;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Kitsu search failed. QLen={Len} Offset={Offset}", normQ.Length, offset);
                return new();
            }
        }

        public Task<ExternalAnimeDto?> GetByIdAsync(string externalId, CancellationToken ct)
            => Task.FromResult<ExternalAnimeDto?>(null); // implementar depois
    }
}
