using AnimeHub.Application.Dtos.Search;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services
{
    //Sim, aqui o Application está usando AppDbContext(Infra). 
    //Para deixar mais “clean” (mais estrito), depois da para extrair um IAnimeReadRepository 
    //no Domain e implementa no Infrastructure.Mas, para o MVP atual (e mantendo qualidade), 
    //isso já é bem consistente com o projeto e evita refatoração gigante.
    public sealed class AnimeSearchService : IAnimeSearchService
    {
        private readonly AppDbContext _db;
        private readonly IEnumerable<IAnimeExternalProvider> _providers;
        private readonly ILogger<AnimeSearchService> _logger;

        public AnimeSearchService(AppDbContext db, IEnumerable<IAnimeExternalProvider> providers, ILogger<AnimeSearchService> logger)
        {
            _db = db;
            _providers = providers;
            _logger = logger;
        }

        public async Task<SearchAnimeResponseDto> SearchAsync(string q, int limit, string? cursor, int? year, IReadOnlyList<string>? genres, CancellationToken ct)
        {
            q = (q ?? string.Empty).Trim();
            if (q.Length == 0)
                return new SearchAnimeResponseDto(Array.Empty<SearchAnimeItemDto>(), null);

            // limites (evita abuso / consumo irrestrito)
            limit = Math.Clamp(limit, 1, 50);

            var hasGenreFilter = genres is { Count: > 0 };
            var genreSet = hasGenreFilter
                ? new HashSet<string>(genres!, StringComparer.OrdinalIgnoreCase)
                : null;

            _logger.LogDebug("Anime search request. Q={Query} Limit={Limit} Year={Year} Genres={Genres} HasCursor={HasCursor}",
                q, limit, year, hasGenreFilter ? string.Join(",", genres!) : "(none)", !string.IsNullOrWhiteSpace(cursor));

            var cur = CursorCodec.DecodeOrNew(cursor);

            // -------- Local (keyset) --------
            // Anime local não possui coluna de gêneros; se o filtro de gênero estiver ativo,
            // itens locais não conseguem satisfazê-lo, então são ignorados.
            var localItems = new List<SearchAnimeItemDto>();
            var rows = new List<AnimeHub.Domain.Entities.Anime>();

            if (!hasGenreFilter)
            {
                var like = q + "%";

                IQueryable<AnimeHub.Domain.Entities.Anime> query = _db.Animes.AsNoTracking()
                    .Where(a => EF.Functions.Like(a.Title, like));

                if (year.HasValue)
                    query = query.Where(a => a.Year == year.Value);

                if (!string.IsNullOrWhiteSpace(cur.LocalLastTitle) && cur.LocalLastId.HasValue)
                {
                    var lastTitle = cur.LocalLastTitle!;
                    var lastId = cur.LocalLastId.Value;

                    query = query.Where(a =>
                        string.Compare(a.Title, lastTitle) > 0 ||
                        (a.Title == lastTitle && a.Id > lastId));
                }

                query = query.OrderBy(a => a.Title).ThenBy(a => a.Id);

                rows = await query.Take(limit).ToListAsync(ct);

                localItems = rows.Select(a => new SearchAnimeItemDto(
                    Source: "local",
                    Id: a.Id,
                    ExternalId: null,
                    Title: a.Title,
                    Year: a.Year,
                    Score: a.Score,
                    CoverUrl: a.CoverUrl,
                    Genres: []
                )).ToList();
            }

            _logger.LogDebug("Anime search local results. Count={Count}", localItems.Count);

            // monta o next cursor (unificado)
            var next = new UnifiedSearchCursor();

            if (rows.Count > 0)
            {
                var last = rows[^1];
                next.LocalLastTitle = last.Title;
                next.LocalLastId = last.Id;
            }

            // -------- Externos (providers) --------
            var extLimit = Math.Min(12, limit);

            var pageJikan = cur.JikanPage is > 0 ? cur.JikanPage.Value : 1;
            var pageAniList = cur.AniListPage is > 0 ? cur.AniListPage.Value : 1;
            var offsetKitsu = cur.KitsuOffset is >= 0 ? cur.KitsuOffset.Value : 0;

            var tasks = _providers.Select(p =>
            {
                var arg = p.Provider switch
                {
                    "Kitsu" => offsetKitsu,
                    "AniList" => pageAniList,
                    "Jikan" => pageJikan,
                    _ => pageJikan
                };

                return p.SearchAsync(q, arg, extLimit, ct);
            }).ToArray();

            var results = await Task.WhenAll(tasks);
            var extDtos = results.SelectMany(x => x).ToList();

            if (year.HasValue)
                extDtos = extDtos.Where(x => x.Year == year.Value).ToList();

            // Filtro por gênero (OR): mantém itens que possuam pelo menos um dos gêneros solicitados
            if (hasGenreFilter)
                extDtos = extDtos.Where(x => x.Genres.Any(g => genreSet!.Contains(g))).ToList();

            _logger.LogDebug("Anime search external results. Count={Count}", extDtos.Count);

            var externalItems = extDtos.Select(x => new SearchAnimeItemDto(
                Source: x.Provider,  // "Jikan" | "AniList" | "Kitsu"
                Id: null,
                ExternalId: x.ExternalId,
                Title: x.Title,
                Year: x.Year,
                Score: x.Score,
                CoverUrl: x.CoverUrl,
                Genres: x.Genres
            )).ToList();

            // avança cursores por provider (só se veio algo daquele provider)
            next.JikanPage = extDtos.Any(x => x.Provider == "Jikan") ? pageJikan + 1 : pageJikan;
            next.AniListPage = extDtos.Any(x => x.Provider == "AniList") ? pageAniList + 1 : pageAniList;

            // kitsu usa offset
            next.KitsuOffset = extDtos.Any(x => x.Provider == "Kitsu") ? offsetKitsu + extLimit : offsetKitsu;

            // junta tudo (sem deduplicar)
            var items = localItems.Concat(externalItems).ToList();

            var nextCursor = items.Count > 0 ? CursorCodec.Encode(next) : null;

            _logger.LogDebug("Anime search response built. TotalItems={Total} HasNextCursor={HasNextCursor}",
                items.Count, !string.IsNullOrWhiteSpace(nextCursor));

            return new SearchAnimeResponseDto(items, nextCursor);
        }

    }
}
