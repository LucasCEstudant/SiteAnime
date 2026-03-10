using AnimeHub.Application.Dtos.External;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.Jikan;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services.Providers
{
    public sealed class JikanProvider : IAnimeExternalProvider
    {
        public string Provider => "Jikan";

        private readonly JikanClient _client;
        private readonly IMemoryCache _cache;
        private readonly JikanRateLimiter _limiter;
        private readonly ILogger<JikanProvider> _logger;

        public JikanProvider(JikanClient client, IMemoryCache cache, JikanRateLimiter limiter, ILogger<JikanProvider> logger)
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
            limit = Math.Clamp(limit, 1, 25); // bom para autocomplete

            var normQ = q.ToLowerInvariant();
            var cacheKey = $"jikan:search:q={normQ}:p={page}:l={limit}";

            if (_cache.TryGetValue(cacheKey, out List<ExternalAnimeDto>? cached) && cached is not null)
                return cached;

            // Rate limit oficial: 3/s e 60/min
            if (!await _limiter.TryAcquireAsync(ct))
            {
                _logger.LogWarning("Jikan rate limited. QLen={Len} Page={Page}", normQ.Length, page);
                return new();
            }

            try
            {
                var res = await _client.SearchAsync(q, page, limit, ct);
                if (res?.Data is null) return new();

                var mapped = res.Data.Select(x => new ExternalAnimeDto(
                    Provider: Provider,
                    ExternalId: x.Mal_Id.ToString(),
                    Title: x.Title,
                    Synopsis: x.Synopsis,
                    Year: x.Year,
                    Score: x.Score,
                    CoverUrl: x.Images?.Jpg?.Image_Url,
                    Genres: x.Genres?.Select(g => g.Name).Where(n => !string.IsNullOrWhiteSpace(n)).Select(n => n!).ToList()
                        ?? (IReadOnlyList<string>)[]
                )).ToList();

                // Sliding + Absolute recomendado pela Microsoft
                _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
                {
                    SlidingExpiration = TimeSpan.FromSeconds(15),
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
                });

                return mapped;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Jikan search failed. QLen={Len} Page={Page}", normQ.Length, page);
                return new();
            }
        }

        public async Task<ExternalAnimeDto?> GetByIdAsync(string externalId, CancellationToken ct)
        {
            if (!int.TryParse(externalId, out var malId)) return null;

            var cacheKey = $"jikan:get:id={malId}";
            if (_cache.TryGetValue(cacheKey, out ExternalAnimeDto? cached) && cached is not null)
                return cached;

            if (!await _limiter.TryAcquireAsync(ct))
            {
                _logger.LogWarning("Jikan getById rate limited. MalId={MalId}", malId);
                return null;
            }

            try
            {
                var res = await _client.GetByIdAsync(malId, ct);
                var x = res?.Data;
                if (x is null) return null;

                var dto = new ExternalAnimeDto(
                    Provider: Provider,
                    ExternalId: x.Mal_Id.ToString(),
                    Title: x.Title,
                    Synopsis: x.Synopsis,
                    Year: x.Year,
                    Score: x.Score,
                    CoverUrl: x.Images?.Jpg?.Image_Url,
                    Genres: x.Genres?.Select(g => g.Name).Where(n => !string.IsNullOrWhiteSpace(n)).Select(n => n!).ToList()
                        ?? (IReadOnlyList<string>)[]
                );

                _cache.Set(cacheKey, dto, new MemoryCacheEntryOptions
                {
                    SlidingExpiration = TimeSpan.FromMinutes(2),
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
                });

                return dto;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Jikan getById failed. MalId={MalId}", malId);
                return null;
            }
        }
    }
}
