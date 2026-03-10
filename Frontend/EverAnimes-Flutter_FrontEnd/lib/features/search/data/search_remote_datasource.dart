import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/paginated_anime_response_dto.dart';

/// Datasource remoto para o endpoint de busca de animes.
///
/// Consome `GET /api/animes/search` e `GET /api/animes/filters/genre`.
class SearchRemoteDatasource {
  const SearchRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca animes por termo.
  ///
  /// [query] — termo de busca (obrigatório, max 100 chars).
  /// [limit] — quantidade por página (1-50).
  /// [cursor] — cursor opaco para próxima página (null = primeira).
  /// [year] — filtro opcional de ano (1900-2100).
  /// [genres] — filtro opcional de gêneros (lista de strings).
  Future<PaginatedAnimeResponseDto> search({
    required String query,
    int limit = 15,
    String? cursor,
    int? year,
    List<String>? genres,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/animes/search',
      queryParameters: <String, dynamic>{
        'q': query,
        'limit': limit,
        'Cursor': ?cursor,
        if (year != null) 'year': year,
        if (genres != null && genres.isNotEmpty) 'Genres': genres,
      },
    );
    return PaginatedAnimeResponseDto.fromJson(response.data!);
  }

  /// Busca animes por gênero (sem texto de busca).
  ///
  /// [genre] — gêneros separados por vírgula (ex: "Action,Comedy").
  /// [limit] — quantidade por página (1-50).
  /// [cursor] — cursor opaco para próxima página (null = primeira).
  Future<PaginatedAnimeResponseDto> fetchByGenre({
    required String genre,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/animes/filters/genre',
      queryParameters: <String, dynamic>{
        'Genre': genre,
        'Limit': limit,
        'Cursor': ?cursor,
      },
    );
    return PaginatedAnimeResponseDto.fromJson(response.data!);
  }

  /// Busca animes por ano de lançamento.
  ///
  /// [year] — ano (ex: 2025).
  /// [limit] — quantidade por página (1-50).
  /// [cursor] — cursor opaco para próxima página (null = primeira).
  Future<PaginatedAnimeResponseDto> fetchByYear({
    required int year,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/animes/filters/year',
      queryParameters: <String, dynamic>{
        'Year': year,
        'Limit': limit,
        'Cursor': ?cursor,
      },
    );
    return PaginatedAnimeResponseDto.fromJson(response.data!);
  }
}
