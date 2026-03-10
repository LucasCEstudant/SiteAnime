using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.AniList;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class AniListMetaService : IAniListMetaService
{
    private const string CacheKey = "anilist:genres:v1";
    private readonly AniListClient _client;
    private readonly IMemoryCache _cache;
    private readonly ILogger<AniListMetaService> _logger;
    private static readonly TimeSpan GenresCacheTtl = TimeSpan.FromHours(24);

    public AniListMetaService(AniListClient client, IMemoryCache cache, ILogger<AniListMetaService> logger)
    {
        _client = client;
        _cache = cache;
        _logger = logger;
    }

    public async Task<IReadOnlyList<string>> ListAllAvailableGenresAsync(CancellationToken ct)
    {
        if (_cache.TryGetValue(CacheKey, out List<string>? cached) && cached is not null)
            return cached;

        var genres = await _client.GetGenresAsync(ct);

        // normaliza: remove vazios, ordena, remove duplicados
        var normalized = genres
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x, StringComparer.OrdinalIgnoreCase)
            .ToList();

        _cache.Set(CacheKey, normalized, new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = GenresCacheTtl
        });

        _logger.LogInformation("AniList genres loaded. Count={Count}", normalized.Count);
        return normalized;
    }
}