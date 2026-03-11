import '../../../core/api/api_client.dart';
import 'dtos/user_anime_dtos.dart';

/// Remote data-source para o recurso `/api/users/me/animes`.
class UserAnimesRemoteDatasource {
  const UserAnimesRemoteDatasource(this._client);

  final ApiClient _client;

  /// Verifica se um anime local (por animeId) já existe na lista do usuário.
  ///
  /// Busca page 1 com pageSize 1 e filtra no servidor (se suportado) ou
  /// faz uma busca completa e compara no cliente.
  Future<bool> existsByAnimeId(int animeId) async {
    // A API não filtra por animeId diretamente, então buscamos todos os itens
    // e verificamos no cliente. Para listas grandes isso é sub-ótimo, mas
    // evita duplicatas até o backend suportar filtro por animeId.
    final response = await _client.get<Map<String, dynamic>>(
      '/api/users/me/animes',
      queryParameters: <String, dynamic>{
        'page': 1,
        'pageSize': 200,
      },
    );
    final page = UserAnimePagedResponseDto.fromJson(response.data!);
    return page.items.any((item) => item.animeId == animeId);
  }

  /// Adiciona um anime à lista do usuário.
  ///
  /// Retorna o [UserAnimeDto] criado (201).
  /// A API retorna 409 (Conflict) se o anime já estiver na lista.
  Future<UserAnimeDto> add(UserAnimeCreateDto dto) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/users/me/animes',
      data: dto.toJson(),
    );
    return UserAnimeDto.fromJson(response.data!);
  }

  /// Busca a lista de animes do usuário com paginação e filtros opcionais.
  Future<UserAnimePagedResponseDto> getAll({
    String? status,
    int? year,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/users/me/animes',
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'status': ?status,
        'year': ?year,
      },
    );
    return UserAnimePagedResponseDto.fromJson(response.data!);
  }

  /// Atualiza parcialmente uma entrada da lista do usuário (204).
  Future<void> update(int id, UserAnimeUpdateDto dto) async {
    await _client.put<void>(
      '/api/users/me/animes/$id',
      data: dto.toJson(),
    );
  }

  /// Remove uma entrada da lista do usuário (204).
  Future<void> delete(int id) async {
    await _client.delete<void>('/api/users/me/animes/$id');
  }
}
