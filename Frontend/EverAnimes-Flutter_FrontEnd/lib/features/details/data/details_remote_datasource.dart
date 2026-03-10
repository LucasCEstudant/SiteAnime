import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'dtos/anime_details_dto.dart';

/// Datasource remoto para `GET /api/animes/details`.
class DetailsRemoteDatasource {
  DetailsRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca detalhes de um anime por [source] + ([id] ou [externalId]).
  Future<AnimeDetailsDto> fetchDetails({
    required String source,
    int? id,
    String? externalId,
  }) async {
    final response = await _client.get(
      '/api/animes/details',
      queryParameters: {
        'source': source,
        'id': ?id,
        'externalId': ?externalId,
      },
    );

    if (response.data == null) {
      throw ApiException(message: 'Resposta vazia da API', statusCode: 0);
    }

    return AnimeDetailsDto.fromJson(response.data as Map<String, dynamic>);
  }
}
