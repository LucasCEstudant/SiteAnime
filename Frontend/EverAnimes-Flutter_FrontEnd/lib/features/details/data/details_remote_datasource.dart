import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'dtos/anime_details_dto.dart';

/// Datasource remoto para detalhes de anime.
///
/// * Local  → `GET /api/animes/details?source=local&id={id}`
/// * Externo → `GET /api/animes/details?source={source}&externalId={externalId}`
class DetailsRemoteDatasource {
  DetailsRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca detalhes de um anime por [source] + ([id] ou [externalId]).
  ///
  /// Valida os parâmetros antes de fazer a chamada para evitar 400 do backend.
  Future<AnimeDetailsDto> fetchDetails({
    required String source,
    int? id,
    String? externalId,
  }) async {
    final isLocal = source.toLowerCase() == 'local';

    // ── Validações preventivas ───────────────────────────────────────
    if (isLocal && (id == null || id <= 0)) {
      throw ApiException(
        message: 'ID inválido para anime local.',
        statusCode: 400,
      );
    }

    if (!isLocal && (externalId == null || externalId.isEmpty)) {
      throw ApiException(
        message: 'ExternalId ausente para anime externo.',
        statusCode: 400,
      );
    }

    // ── Chamada ──────────────────────────────────────────────────────
    final queryParams = <String, dynamic>{
      'source': source,
      if (isLocal) 'id': id,
      if (!isLocal) 'externalId': externalId,
    };

    final response = await _client.get(
      '/api/animes/details',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      throw ApiException(message: 'Resposta vazia da API', statusCode: 0);
    }

    return AnimeDetailsDto.fromJson(response.data as Map<String, dynamic>);
  }
}
