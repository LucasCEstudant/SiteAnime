import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/paginated_anime_response_dto.dart';

/// Datasource remoto para endpoints de animes (filtros).
/// Etapa 5: apenas season/now.
class AnimeRemoteDatasource {
  const AnimeRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca animes da temporada atual.
  ///
  /// [limit] — quantidade de itens por página.
  /// [cursor] — cursor opaco para próxima página (null = primeira).
  Future<PaginatedAnimeResponseDto> fetchSeasonNow({
    int limit = 15,
    String? cursor,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/animes/filters/season/now',
      queryParameters: <String, dynamic>{
        'Limit': limit,
        'Cursor': ?cursor,
      },
    );
    return PaginatedAnimeResponseDto.fromJson(response.data!);
  }
}
