using AnimeHub.Application.Dtos.Filters;
using AnimeHub.Application.Helpers;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.AniList;
using AnimeHub.Infrastructure.External.Jikan;
using AnimeHub.Infrastructure.External.Kitsu;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class AnimeFiltersService : IAnimeFiltersService
{
    private readonly AppDbContext _db;
    private readonly AniListClient _aniList;
    private readonly KitsuClient _kitsu;
    private readonly JikanClient _jikan;

    private readonly IMemoryCache _cache;
    private readonly AniListRateLimiter _aniListLimiter;
    private readonly KitsuRateLimiter _kitsuLimiter;
    private readonly JikanRateLimiter _jikanLimiter;

    private readonly ILogger<AnimeFiltersService> _logger;

    public AnimeFiltersService(
        AppDbContext db,
        AniListClient aniList,
        KitsuClient kitsu,
        JikanClient jikan,
        IMemoryCache cache,
        AniListRateLimiter aniListLimiter,
        KitsuRateLimiter kitsuLimiter,
        JikanRateLimiter jikanLimiter,
        ILogger<AnimeFiltersService> logger)
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

    public Task<FilterAnimeResponseDto> ByGenreAsync(string genre, int limit, string? cursor, CancellationToken ct)
        => FilterCoreAsync(mode: "genre", genre: genre, year: null, limit: limit, cursor: cursor, ct: ct);

    public Task<FilterAnimeResponseDto> ByYearAsync(int year, int limit, string? cursor, CancellationToken ct)
        => FilterCoreAsync(mode: "year", genre: null, year: year, limit: limit, cursor: cursor, ct: ct);

    public Task<FilterAnimeResponseDto> SeasonNowAsync(int limit, string? cursor, CancellationToken ct)
        => FilterCoreAsync(mode: "season_now", genre: null, year: null, limit: limit, cursor: cursor, ct: ct);

    private async Task<FilterAnimeResponseDto> FilterCoreAsync(
        string mode,
        string? genre,
        int? year,
        int limit,
        string? cursor,
        CancellationToken ct)
    {
        limit = Math.Clamp(limit, 1, 50);

        var cur = FiltersCursorCodec.DecodeOrNew(cursor);

        // ---- Local (apenas no filtro por ano) ----
        var localItems = new List<FilterAnimeItemDto>();

        if (mode == "year" && year.HasValue)
        {
            IQueryable<AnimeHub.Domain.Entities.Anime> qLocal = _db.Animes.AsNoTracking()
                .Where(a => a.Year == year.Value);

            if (!string.IsNullOrWhiteSpace(cur.LocalLastTitle) && cur.LocalLastId.HasValue)
            {
                var lastTitle = cur.LocalLastTitle!;
                var lastId = cur.LocalLastId.Value;

                qLocal = qLocal.Where(a =>
                    string.Compare(a.Title, lastTitle) > 0 ||
                    (a.Title == lastTitle && a.Id > lastId));
            }

            qLocal = qLocal.OrderBy(a => a.Title).ThenBy(a => a.Id);

            var rows = await qLocal.Take(limit).ToListAsync(ct);

            localItems = rows.Select(a => new FilterAnimeItemDto(
                Source: "local",
                Id: a.Id,
                ExternalId: null,
                Title: a.Title,
                Year: a.Year,
                Score: a.Score,
                CoverUrl: a.CoverUrl,
                Genres: []
            )).ToList();

            if (rows.Count > 0)
            {
                var last = rows[^1];
                cur.LocalLastTitle = last.Title;
                cur.LocalLastId = last.Id;
            }
        }

        // ---- Externos ----
        var extLimit = Math.Min(12, limit);
        var extItems = new List<FilterAnimeItemDto>();

        var aniPage = cur.AniListPage is > 0 ? cur.AniListPage.Value : 1;
        var kitsuOffset = cur.KitsuOffset is >= 0 ? cur.KitsuOffset.Value : 0;
        var jikanPage = cur.JikanPage is > 0 ? cur.JikanPage.Value : 1;

        Task<List<FilterAnimeItemDto>>? aniTask = null;
        Task<List<FilterAnimeItemDto>>? kitsuTask = null;
        Task<List<FilterAnimeItemDto>>? jikanTask = null;

        if (mode == "genre" && !string.IsNullOrWhiteSpace(genre))
        {
            aniTask = AniListByGenreAsync(genre!, aniPage, extLimit, ct);

            // Kitsu: max 20 por request 
            kitsuTask = KitsuByGenreAsync(genre!, kitsuOffset, Math.Min(20, extLimit), ct);
        }
        else if (mode == "year" && year.HasValue)
        {
            aniTask = AniListByYearAsync(year.Value, aniPage, extLimit, ct);
        }
        else if (mode == "season_now")
        {
            // Jikan possui endpoint de seasons na v4 
            jikanTask = JikanSeasonNowAsync(jikanPage, extLimit, ct);
            aniTask = AniListSeasonNowAsync(aniPage, extLimit, ct);
        }

        var awaitables = new List<Task>();
        if (aniTask is not null) awaitables.Add(aniTask);
        if (kitsuTask is not null) awaitables.Add(kitsuTask);
        if (jikanTask is not null) awaitables.Add(jikanTask);

        await Task.WhenAll(awaitables);

        var aniResult = aniTask is null ? new List<FilterAnimeItemDto>() : await aniTask;
        var kitsuResult = kitsuTask is null ? new List<FilterAnimeItemDto>() : await kitsuTask;
        var jikanResult = jikanTask is null ? new List<FilterAnimeItemDto>() : await jikanTask;

        if (aniResult.Count > 0)
        {
            extItems.AddRange(aniResult);
            cur.AniListPage = aniResult.Count == extLimit ? aniPage + 1 : aniPage;
        }

        if (kitsuResult.Count > 0)
        {
            extItems.AddRange(kitsuResult);

            // offset avança pelo que realmente voltou (evita pular/duplicar)
            cur.KitsuOffset = kitsuOffset + kitsuResult.Count;
        }

        if (jikanResult.Count > 0)
        {
            extItems.AddRange(jikanResult);
            cur.JikanPage = jikanResult.Count == extLimit ? jikanPage + 1 : jikanPage;
        }

        var items = localItems.Concat(extItems).ToList();
        var nextCursor = items.Count > 0 ? FiltersCursorCodec.Encode(cur) : null;

        return new FilterAnimeResponseDto(items, nextCursor);
    }

    // ----------------- Externos com cache + limiter (cache miss only) -----------------

    private async Task<List<FilterAnimeItemDto>> AniListByGenreAsync(string genre, int page, int limit, CancellationToken ct)
    {
        genre = genre.Trim();
        if (genre.Length == 0) return new();

        var cacheKey = $"filters:anilist:genre={genre.ToLowerInvariant()}:p={page}:l={limit}";
        if (_cache.TryGetValue(cacheKey, out List<FilterAnimeItemDto>? cached) && cached is not null)
            return cached;

        // AniList: 90 req/min 
        if (!await _aniListLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("AniList rate limited (genre). Genre={Genre} Page={Page}", genre, page);
            return new();
        }

        try
        {
            var res = await _aniList.SearchByGenreAsync(genre, page, limit, ct);
            var media = res?.Data?.Page?.Media ?? new();

            var mapped = media.Select(m => new FilterAnimeItemDto(
                Source: "AniList",
                Id: null,
                ExternalId: m.Id.ToString(),
                Title: m.Title?.UserPreferred ?? $"AniList #{m.Id}",
                Year: m.StartDate?.Year,
                Score: m.AverageScore.HasValue ? (decimal?)m.AverageScore.Value / 10m : null,
                CoverUrl: m.CoverImage?.Large,
                Genres: m.Genres?.Where(g => !string.IsNullOrWhiteSpace(g)).ToList()
                    ?? (IReadOnlyList<string>)[]
            )).ToList();

            _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromSeconds(15),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
            });

            return mapped;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AniList genre filter failed. Genre={Genre} Page={Page}", genre, page);
            return new();
        }
    }

    private async Task<List<FilterAnimeItemDto>> AniListByYearAsync(int year, int page, int limit, CancellationToken ct)
    {
        var cacheKey = $"filters:anilist:year={year}:p={page}:l={limit}";
        if (_cache.TryGetValue(cacheKey, out List<FilterAnimeItemDto>? cached) && cached is not null)
            return cached;

        // AniList: 90 req/min 
        if (!await _aniListLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("AniList rate limited (year). Year={Year} Page={Page}", year, page);
            return new();
        }

        try
        {
            var res = await _aniList.SearchByYearAsync(year, page, limit, ct);
            var media = res?.Data?.Page?.Media ?? new();

            var mapped = media.Select(m => new FilterAnimeItemDto(
                Source: "AniList",
                Id: null,
                ExternalId: m.Id.ToString(),
                Title: m.Title?.UserPreferred ?? $"AniList #{m.Id}",
                Year: m.StartDate?.Year,
                Score: m.AverageScore.HasValue ? (decimal?)m.AverageScore.Value / 10m : null,
                CoverUrl: m.CoverImage?.Large,
                Genres: m.Genres?.Where(g => !string.IsNullOrWhiteSpace(g)).ToList()
                    ?? (IReadOnlyList<string>)[]
            )).ToList();

            _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromSeconds(15),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
            });

            return mapped;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AniList year filter failed. Year={Year} Page={Page}", year, page);
            return new();
        }
    }

    private async Task<List<FilterAnimeItemDto>> AniListSeasonNowAsync(int page, int limit, CancellationToken ct)
    {
        var (season, seasonYear) = SeasonHelper.GetCurrentSeasonUtc();

        var cacheKey = $"filters:anilist:season={season}:{seasonYear}:p={page}:l={limit}";
        if (_cache.TryGetValue(cacheKey, out List<FilterAnimeItemDto>? cached) && cached is not null)
            return cached;

        // AniList: 90 req/min
        if (!await _aniListLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("AniList rate limited (season). Season={Season} Year={Year} Page={Page}", season, seasonYear, page);
            return new();
        }

        try
        {
            var res = await _aniList.SearchBySeasonAsync(season, seasonYear, page, limit, ct);
            var media = res?.Data?.Page?.Media ?? new();

            var mapped = media.Select(m => new FilterAnimeItemDto(
                Source: "AniList",
                Id: null,
                ExternalId: m.Id.ToString(),
                Title: m.Title?.UserPreferred ?? $"AniList #{m.Id}",
                Year: m.StartDate?.Year,
                Score: m.AverageScore.HasValue ? (decimal?)m.AverageScore.Value / 10m : null,
                CoverUrl: m.CoverImage?.Large,
                Genres: m.Genres?.Where(g => !string.IsNullOrWhiteSpace(g)).ToList()
                    ?? (IReadOnlyList<string>)[]
            )).ToList();

            _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromSeconds(15),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
            });

            return mapped;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AniList season-now failed. Season={Season} Year={Year} Page={Page}", season, seasonYear, page);
            return new();
        }
    }

    private async Task<List<FilterAnimeItemDto>> KitsuByGenreAsync(string genreSlug, int offset, int limit, CancellationToken ct)
    {
        genreSlug = genreSlug.Trim();
        if (genreSlug.Length == 0) return new();

        // Kitsu max 20
        limit = Math.Clamp(limit, 1, 20);
        offset = Math.Max(0, offset);

        var cacheKey = $"filters:kitsu:genre={genreSlug.ToLowerInvariant()}:o={offset}:l={limit}";
        if (_cache.TryGetValue(cacheKey, out List<FilterAnimeItemDto>? cached) && cached is not null)
            return cached;

        if (!await _kitsuLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("Kitsu rate limited (genre). Genre={Genre} Offset={Offset}", genreSlug, offset);
            return new();
        }

        try
        {
            var res = await _kitsu.SearchByCategoryAsync(genreSlug, offset, limit, ct);
            var data = res?.Data ?? new();
            var included = res?.Included;

            var mapped = data.Select(d =>
            {
                var a = d.Attributes;

                int? year = null;
                if (!string.IsNullOrWhiteSpace(a?.StartDate) && a.StartDate.Length >= 4
                    && int.TryParse(a.StartDate[..4], out var y))
                    year = y;

                decimal? score = null;
                if (!string.IsNullOrWhiteSpace(a?.AverageRating)
                    && decimal.TryParse(a.AverageRating, System.Globalization.NumberStyles.Any,
                        System.Globalization.CultureInfo.InvariantCulture, out var r))
                    score = Math.Round(r / 10m, 2);

                return new FilterAnimeItemDto(
                    Source: "Kitsu",
                    Id: null,
                    ExternalId: d.Id,
                    Title: a?.CanonicalTitle ?? "Unknown",
                    Year: year,
                    Score: score,
                    CoverUrl: a?.PosterImage?.Large,
                    Genres: AnimeHub.Infrastructure.External.Kitsu.KitsuCategoryHelper.ExtractCategories(d, included)
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
            _logger.LogError(ex, "Kitsu genre filter failed. Genre={Genre} Offset={Offset}", genreSlug, offset);
            return new();
        }
    }

    private async Task<List<FilterAnimeItemDto>> JikanSeasonNowAsync(int page, int limit, CancellationToken ct)
    {
        var cacheKey = $"filters:jikan:season-now:p={page}:l={limit}";
        if (_cache.TryGetValue(cacheKey, out List<FilterAnimeItemDto>? cached) && cached is not null)
            return cached;

        // Jikan: endpoint seasons existe na v4
        if (!await _jikanLimiter.TryAcquireAsync(ct))
        {
            _logger.LogWarning("Jikan rate limited (season-now). Page={Page}", page);
            return new();
        }

        try
        {
            var res = await _jikan.SeasonNowAsync(page, limit, ct);
            if (res?.Data is null) return new();

            var mapped = res.Data.Select(x => new FilterAnimeItemDto(
                Source: "Jikan",
                Id: null,
                ExternalId: x.Mal_Id.ToString(),
                Title: x.Title,
                Year: x.Year,
                Score: x.Score,
                CoverUrl: x.Images?.Jpg?.Image_Url,
                Genres: x.Genres?.Select(g => g.Name).Where(n => !string.IsNullOrWhiteSpace(n)).Select(n => n!).ToList()
                    ?? (IReadOnlyList<string>)[]
            )).ToList();

            _cache.Set(cacheKey, mapped, new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromSeconds(15),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(30)
            });

            return mapped;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Jikan season-now failed. Page={Page}", page);
            return new();
        }
    }
}