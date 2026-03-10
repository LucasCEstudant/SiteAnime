using AnimeHub.Application.Dtos.Details;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.AniList;
using AnimeHub.Infrastructure.External.Jikan;
using AnimeHub.Infrastructure.External.Kitsu;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class AnimeDetailsService : IAnimeDetailsService
{
    private readonly AppDbContext _db;
    private readonly AniListClient _aniList;
    private readonly KitsuClient _kitsu;
    private readonly JikanClient _jikan;

    private readonly IMemoryCache _cache;
    private readonly AniListRateLimiter _aniListLimiter;
    private readonly KitsuRateLimiter _kitsuLimiter;
    private readonly JikanRateLimiter _jikanLimiter;
    private readonly ILogger<AnimeDetailsService> _logger;

    public AnimeDetailsService(
        AppDbContext db,
        AniListClient aniList,
        KitsuClient kitsu,
        JikanClient jikan,
        IMemoryCache cache,
        AniListRateLimiter aniListLimiter,
        KitsuRateLimiter kitsuLimiter,
        JikanRateLimiter jikanLimiter,
        ILogger<AnimeDetailsService> logger)
    {
        _db = db;
        _aniList = aniList;
        _kitsu = kitsu;
        _jikan = jikan;
        _cache = cache;
        _aniListLimiter = aniListLimiter;
        _kitsuLimiter = kitsuLimiter;
        _jikanLimiter = jikanLimiter;
        _logger = logger;
    }

    public async Task<AnimeDetailsDto?> GetAsync(string source, int? id, string? externalId, CancellationToken ct)
    {
        source = (source ?? "").Trim();

        if (source.Equals("local", StringComparison.OrdinalIgnoreCase))
        {
            if (!id.HasValue) return null;

            var a = await _db.Animes.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id.Value, ct);
            if (a is null) return null;

            return new AnimeDetailsDto(
                Source: "local",
                Id: a.Id,
                ExternalId: null,
                Title: a.Title,
                Synopsis: a.Synopsis,
                Year: a.Year,
                Score: a.Score,
                CoverUrl: a.CoverUrl,
                EpisodeCount: a.EpisodeCount,
                EpisodeLength: a.EpisodeLengthMinutes,
                Genres: [],
                ExternalLinks: a.ExternalLinks
                    .Select(x => new AnimeExternalLinkDto(x.Site, x.Url))
                    .ToList(),
                StreamingEpisodes: a.StreamingEpisodes
                    .Select(x => new AnimeStreamingEpisodeDto(x.Title, x.Url, x.Site))
                    .ToList()
            );
        }

        if (string.IsNullOrWhiteSpace(externalId)) return null;

        var cacheKey = $"details:{source}:{externalId}".ToLowerInvariant();
        if (_cache.TryGetValue(cacheKey, out AnimeDetailsDto? cached) && cached is not null)
            return cached;

        AnimeDetailsDto? details = source switch
        {
            "AniList" => await AniListDetailsAsync(externalId!, ct),
            "Jikan" => await JikanDetailsAsync(externalId!, ct),
            "Kitsu" => await KitsuDetailsAsync(externalId!, ct),
            _ => null
        };

        if (details is null) return null;

        _cache.Set(cacheKey, details, new MemoryCacheEntryOptions
        {
            SlidingExpiration = TimeSpan.FromMinutes(2),
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
        });

        return details;
    }

    private async Task<AnimeDetailsDto?> AniListDetailsAsync(string externalId, CancellationToken ct)
    {
        if (!int.TryParse(externalId, out var id)) return null;

        if (!await _aniListLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("AniList rate limited (details). Id={Id}", id);
            return null;
        }

        var res = await _aniList.GetByIdAsync(id, ct);
        var m = res?.Data?.Media;
        if (m is null) return null;

        var links = (m.ExternalLinks ?? new())
            .Where(x => !string.IsNullOrWhiteSpace(x?.Url))
            .Select(x => new AnimeExternalLinkDto(x!.Site ?? "External", x.Url!))
            .ToList();

        var episodes = (m.StreamingEpisodes ?? new())
            .Where(x => !string.IsNullOrWhiteSpace(x?.Url))
            .Select(x => new AnimeStreamingEpisodeDto(
                Title: x!.Title ?? "Episode",
                Url: x.Url!,
                Site: x.Site
            ))
            .ToList();

        return new AnimeDetailsDto(
            Source: "AniList",
            Id: null,
            ExternalId: m.Id.ToString(),
            Title: m.Title?.UserPreferred ?? $"AniList #{m.Id}",
            Synopsis: m.Description,
            Year: m.StartDate?.Year,
            Score: m.AverageScore.HasValue ? (decimal?)m.AverageScore.Value / 10m : null,
            CoverUrl: m.CoverImage?.Large,
            EpisodeCount: m.Episodes,
            EpisodeLength: m.Duration,
            Genres: m.Genres?.Where(g => !string.IsNullOrWhiteSpace(g)).ToList()
                ?? (IReadOnlyList<string>)[],
            ExternalLinks: links,
            StreamingEpisodes: episodes
        );
    }

    private async Task<AnimeDetailsDto?> JikanDetailsAsync(string externalId, CancellationToken ct)
    {
        if (!int.TryParse(externalId, out var malId)) return null;

        if (!await _jikanLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("Jikan rate limited (details). Id={Id}", malId);
            return null;
        }

        var res = await _jikan.GetByIdAsync(malId, ct);
        var x = res?.Data;
        if (x is null) return null;

        return new AnimeDetailsDto(
            Source: "Jikan",
            Id: null,
            ExternalId: x.Mal_Id.ToString(),
            Title: x.Title,
            Synopsis: x.Synopsis,
            Year: x.Year,
            Score: x.Score,
            CoverUrl: x.Images?.Jpg?.Image_Url,
            EpisodeCount: x.Episodes,
            EpisodeLength: AnimeHub.Application.Helpers.JikanDurationParserHelper.ParseMinutes(x.Duration),
            Genres: x.Genres?.Select(g => g.Name).Where(n => !string.IsNullOrWhiteSpace(n)).Select(n => n!).ToList()
                ?? (IReadOnlyList<string>)[],
            ExternalLinks: Array.Empty<AnimeExternalLinkDto>(),
            StreamingEpisodes: Array.Empty<AnimeStreamingEpisodeDto>()
        );
    }

    private async Task<AnimeDetailsDto?> KitsuDetailsAsync(string externalId, CancellationToken ct)
    {
        if (!await _kitsuLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("Kitsu rate limited (details). Id={Id}", externalId);
            return null;
        }

        var res = await _kitsu.GetByIdAsync(externalId, ct);
        var d = res?.Data;
        if (d?.Attributes is null) return null;

        var a = d.Attributes;

        int? year = null;
        if (!string.IsNullOrWhiteSpace(a.StartDate) && a.StartDate.Length >= 4 && int.TryParse(a.StartDate[..4], out var y))
            year = y;

        decimal? score = null;
        if (!string.IsNullOrWhiteSpace(a.AverageRating)
            && decimal.TryParse(a.AverageRating, System.Globalization.NumberStyles.Any,
                System.Globalization.CultureInfo.InvariantCulture, out var r))
            score = Math.Round(r / 10m, 2);

        return new AnimeDetailsDto(
            Source: "Kitsu",
            Id: null,
            ExternalId: d.Id,
            Title: a.CanonicalTitle ?? $"Kitsu {d.Id}",
            Synopsis: a.Synopsis,
            Year: year,
            Score: score,
            CoverUrl: a.PosterImage?.Large,
            EpisodeCount: a.EpisodeCount,
            EpisodeLength: a.EpisodeLength,
            Genres: AnimeHub.Infrastructure.External.Kitsu.KitsuCategoryHelper.ExtractCategories(d, res?.Included),
            ExternalLinks: Array.Empty<AnimeExternalLinkDto>(),
            StreamingEpisodes: Array.Empty<AnimeStreamingEpisodeDto>()
        );
    }
}