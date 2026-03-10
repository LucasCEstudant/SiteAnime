import '../../../core/api/api_client.dart';
import 'dtos/user_dtos.dart';

/// Datasource remoto para CRUD de usuários (admin) — Etapa 13.
class UsersRemoteDatasource {
  UsersRemoteDatasource(this._client);

  final ApiClient _client;

  static const _basePath = '/api/users';

  /// Lista todos os usuários.
  Future<List<UserDto>> getAll() async {
    final response = await _client.get(_basePath);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca um usuário por ID.
  Future<UserDto> getById(int id) async {
    final response = await _client.get('$_basePath/$id');
    return UserDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cria um novo usuário.
  Future<UserDto> create(UserCreateDto dto) async {
    final response = await _client.post(_basePath, data: dto.toJson());
    return UserDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Atualiza um usuário existente.
  Future<void> update(int id, UserUpdateDto dto) async {
    await _client.put('$_basePath/$id', data: dto.toJson());
  }

  /// Exclui um usuário.
  Future<void> delete(int id) async {
    await _client.delete('$_basePath/$id');
  }
}
