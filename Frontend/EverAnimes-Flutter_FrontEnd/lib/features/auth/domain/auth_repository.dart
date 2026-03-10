import '../data/auth_remote_datasource.dart';
import '../data/dtos/auth_dtos.dart';

/// Repository para operações de autenticação.
class AuthRepository {
  AuthRepository(this._datasource);

  final AuthRemoteDatasource _datasource;

  /// Faz login e retorna a resposta com tokens.
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) {
    return _datasource.login(email: email, password: password);
  }

  /// Registra um novo usuário.
  /// Em caso de sucesso a API retorna 201, mas não tokens.
  Future<void> register({
    required String email,
    required String password,
  }) {
    return _datasource.register(email: email, password: password);
  }

  /// Renova tokens usando access + refresh tokens atuais.
  Future<AuthResponseDto> refresh({
    required String accessToken,
    required String refreshToken,
  }) {
    return _datasource.refresh(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
