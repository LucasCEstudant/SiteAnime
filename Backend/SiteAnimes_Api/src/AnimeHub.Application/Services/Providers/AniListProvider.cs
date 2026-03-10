using AnimeHub.Application.Dtos.External;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.AniList;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services.Providers
{
    public sealed class AniListProvider : IAnimeExternalProvider
    {
        public string Provider => "AniList";

        private readonly AniListClient _client;
        private readonly IMemoryCache _cache;
        private readonly AniListRateLimiter _limiter;
        private readonly ILogger<AniListProvider> _logger;

        public AniListProvider(AniListClient client, IMemoryCache cache, AniListRateLimiter limiter, ILogger<AniListProvider> logger)
        {
            _client = client;
            _cache = cache;
            _limiter = limiter;
            _logger = logger;
        }

        public async Task<List<ExternalAnimeDto>> SearchAsync(string q, int page, int limit, CancellationToken ct)
        {
            q = (q ?? "").Trim();
            if (q.Length == 0) return new();

            page = page < 1 ? 1 : page;
            limit = Math.Clamp(limit, 1, 12);

            var normQ = q.ToLowerInvariant();
            var cacheKey = $"anilist:search:q={normQ}:p={page}:l={limit}";

            if (_cache.TryGetValue(cacheKey, out List<ExternalAnimeDto>? cached) && cached is not null)
                return cached;

            if (!await _limiter.TryAcquireAsync(ct))
            {
                _logger.LogWarning("AniList rate limited. Q={Query} Page={Page}", normQ, page);
                return new();
            }

            try
            {
                var res = await _client.SearchAsync(q, page, limit, ct);
                var media = res?.Data?.Page?.Media ?? new();

                var mapped = media.Select(m =>
                {
                    var score10 = m.AverageScore.HasValue ? (decimal?)m.AverageScore.Value / 10m : null; // 0-100 -> 0-10
                    return new ExternalAnimeDto(
                        Provider: Provider,
                        ExternalId: m.Id.ToString(),
                        Title: m.Title?.UserPreferred ?? $"AniList #{m.Id}",
                        Synopsis: m.Description,
                        Year: m.StartDate?.Year,
                        Score: score10,
                        CoverUrl: m.CoverImage?.Large,
                        Genres: m.Genres?.Where(g => !string.IsNullOrWhiteSpace(g)).ToList()
                            ?? (IReadOnlyList<string>)[]
                    );
                }).ToList();

                _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
                {
                    SlidingExpiration = TimeSpan.FromSeconds(15),
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
                });

                return mapped;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AniList search failed. Q={Query} Page={Page}", normQ, page);
                return new();
            }
        }

        public Task<ExternalAnimeDto?> GetByIdAsync(string externalId, CancellationToken ct)
        {
            // opcional depois (para agora, mantém apenas Search no agregador)
            return Task.FromResult<ExternalAnimeDto?>(null);
        }
    }
}
