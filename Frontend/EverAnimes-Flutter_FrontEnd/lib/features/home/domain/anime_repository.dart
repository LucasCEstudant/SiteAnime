import '../data/anime_remote_datasource.dart';
import '../../../core/data/dtos/paginated_anime_response_dto.dart';

/// Repository de animes para a Home.
/// Etapa 5: repassa ao datasource sem cache.
class AnimeRepository {
  const AnimeRepository(this._datasource);

  final AnimeRemoteDatasource _datasource;

  /// Retorna a primeira página de animes da temporada atual.
  Future<PaginatedAnimeResponseDto> getSeasonNow({
    int limit = 15,
    String? cursor,
  }) {
    return _datasource.fetchSeasonNow(limit: limit, cursor: cursor);
  }
}
