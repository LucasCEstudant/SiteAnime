import '../../../core/data/dtos/paginated_anime_response_dto.dart';
import '../data/search_remote_datasource.dart';

/// Repository de busca de animes.
/// Etapa 6: repassa ao datasource sem cache.
class SearchRepository {
  const SearchRepository(this._datasource);

  final SearchRemoteDatasource _datasource;

  /// Busca animes pelo termo informado.
  Future<PaginatedAnimeResponseDto> search({
    required String query,
    int limit = 15,
    String? cursor,
    int? year,
    List<String>? genres,
  }) {
    return _datasource.search(
      query: query,
      limit: limit,
      cursor: cursor,
      year: year,
      genres: genres,
    );
  }

  /// Busca animes por gênero.
  Future<PaginatedAnimeResponseDto> fetchByGenre({
    required String genre,
    int limit = 20,
    String? cursor,
  }) {
    return _datasource.fetchByGenre(
      genre: genre,
      limit: limit,
      cursor: cursor,
    );
  }

  /// Busca animes por ano de lançamento.
  Future<PaginatedAnimeResponseDto> fetchByYear({
    required int year,
    int limit = 20,
    String? cursor,
  }) {
    return _datasource.fetchByYear(
      year: year,
      limit: limit,
      cursor: cursor,
    );
  }
}
