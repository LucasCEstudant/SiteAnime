import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/dtos/auth_dtos.dart';
import '../../features/auth/data/token_storage.dart';

/// Callback para executar o refresh token via API.
typedef RefreshCallback = Future<AuthResponseDto> Function({
  required String accessToken,
  required String refreshToken,
});

/// Callback para atualizar o estado de autenticação após refresh.
typedef OnRefreshSuccess = Future<void> Function(AuthResponseDto response);

/// Callback para forçar logout quando o refresh falha.
typedef OnRefreshFailure = Future<void> Function();

/// Interceptor de autenticação com refresh automático — Etapa 9.
///
/// Usa [QueuedInterceptor] do Dio para garantir que:
/// - Apenas UM refresh é executado por vez (serialização automática);
/// - Requests pendentes aguardam o refresh e são re-executadas;
/// - Se o refresh falhar, faz logout e propaga o erro original.
///
/// Requests para `/api/auth/` são excluídas do interceptor
/// para evitar loop infinito (login/register/refresh não precisam de Bearer).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshCallback,
    required this.onRefreshSuccess,
    required this.onRefreshFailure,
    required Dio dio,
  }) : _dio = dio;

  final TokenStorage tokenStorage;
  final RefreshCallback refreshCallback;
  final OnRefreshSuccess onRefreshSuccess;
  final OnRefreshFailure onRefreshFailure;
  final Dio _dio;

  /// Rotas de auth que NÃO devem receber Bearer (evita loop).
  static const _authPaths = {
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/refresh',
  };

  // ── onRequest: adiciona Bearer se autenticado ────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Não adiciona token em rotas de auth.
    if (_isAuthPath(options.path)) {
      return handler.next(options);
    }

    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  // ── onError: tenta refresh em 401 ────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Só trata 401 em rotas que não são de auth.
    if (err.response?.statusCode != 401 || _isAuthPath(err.requestOptions.path)) {
      return handler.next(err);
    }

    // Lê tokens atuais.
    final stored = await tokenStorage.readAll();
    if (stored == null || stored.refreshToken == null) {
      // Sem refresh token → logout e propaga erro.
      await onRefreshFailure();
      return handler.next(err);
    }

    try {
      // Tenta refresh — apenas 1 por vez graças ao QueuedInterceptor.
      final response = await refreshCallback(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken!,
      );

      // Atualiza tokens no storage e no state.
      await onRefreshSuccess(response);

      // Retry da request original com o novo token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] =
          'Bearer ${response.accessToken}';

      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh falhou → logout e propaga erro original.
      await onRefreshFailure();
      return handler.next(err);
    }
  }

  bool _isAuthPath(String path) =>
      _authPaths.any((authPath) => path.contains(authPath));
}
