import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'dtos/auth_dtos.dart';

/// Datasource remoto para endpoints de autenticação.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final ApiClient _client;

  /// `POST /api/auth/login`
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      data: LoginRequestDto(email: email, password: password).toJson(),
    );

    if (response.data == null) {
      throw const ApiException(message: 'Resposta vazia da API', statusCode: 0);
    }

    return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /api/auth/register`
  /// Retorna `true` se o registro foi bem-sucedido (201).
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _client.post(
      '/api/auth/register',
      data: RegisterRequestDto(email: email, password: password).toJson(),
    );
    // 201 Created — sucesso. Não retorna tokens; o client faz login depois.
  }

  /// `POST /api/auth/refresh`
  Future<AuthResponseDto> refresh({
    required String accessToken,
    required String refreshToken,
  }) async {
    final response = await _client.post(
      '/api/auth/refresh',
      data: RefreshTokenRequestDto(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ).toJson(),
    );

    if (response.data == null) {
      throw const ApiException(
          message: 'Resposta vazia da API', statusCode: 0);
    }

    return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}
