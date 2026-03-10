import '../../../core/api/api_client.dart';
import 'dtos/anime_dtos.dart';

/// Datasource remoto para CRUD de animes (admin) — Etapa 14.
class AnimesRemoteDatasource {
  AnimesRemoteDatasource(this._client);

  final ApiClient _client;

  static const _basePath = '/api/animes';

  /// Lista todos os animes.
  Future<List<AnimeDto>> getAll() async {
    final response = await _client.get(_basePath);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AnimeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca um anime por ID.
  Future<AnimeDto> getById(int id) async {
    final response = await _client.get('$_basePath/$id');
    return AnimeDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cria um novo anime.
  Future<AnimeDto> create(AnimeCreateDto dto) async {
    final response = await _client.post(_basePath, data: dto.toJson());
    return AnimeDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Atualiza um anime existente.
  Future<void> update(int id, AnimeUpdateDto dto) async {
    await _client.put('$_basePath/$id', data: dto.toJson());
  }

  /// Exclui um anime.
  Future<void> delete(int id) async {
    await _client.delete('$_basePath/$id');
  }

  /// Atualiza detalhes locais do anime (episódios, links, streaming).
  Future<void> updateDetails(int id, AnimeLocalDetailsUpdateDto dto) async {
    await _client.put('$_basePath/$id/details', data: dto.toJson());
  }
}
