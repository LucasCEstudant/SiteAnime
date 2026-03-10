import '../../../core/api/api_client.dart';
import 'dtos/genres_response.dart';

/// Datasource que acessa endpoints de metadados AniList.
/// Etapa 4: apenas genres.
class MetaRemoteDatasource {
  const MetaRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca a lista de gêneros disponíveis.
  Future<GenresResponse> fetchGenres() async {
    final response = await _client.get<List<dynamic>>('/api/meta/anilist/genres');
    return GenresResponse.fromJson(response.data!);
  }
}
