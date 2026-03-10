import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';
import 'auth_interceptor.dart';
import '../../features/auth/data/token_storage.dart';
import '../../features/auth/domain/auth_state_provider.dart';
import '../../features/auth/data/auth_remote_datasource.dart';

/// URL base da API.
/// Em containers Docker é vazio (nginx faz proxy reverso para /api).
/// Em desenvolvimento local usa http://localhost:7118.
/// Configurável via --dart-define=API_BASE_URL=...
const String _kConfiguredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String get kApiBaseUrl {
  final configured = _kConfiguredApiBaseUrl.trim();
  if (configured.isNotEmpty) {
    // Em produção web, nunca permitir localhost/loopback.
    if (kIsWeb && kReleaseMode) {
      final lowered = configured.toLowerCase();
      final isLoopback = lowered.contains('localhost') || lowered.contains('127.0.0.1');
      if (isLoopback) return '';
    }
    return configured;
  }

  // Em release web, usa URL relativa para evitar localhost hardcoded.
  if (kIsWeb && kReleaseMode) return '';

  // Fallback para desenvolvimento local.
  return 'http://localhost:7118';
}

/// Timeout padrão para requests.
const Duration _kConnectTimeout = Duration(seconds: 10);
const Duration _kReceiveTimeout = Duration(seconds: 15);

/// Provider que expõe o [ApiClient] para toda a aplicação.
/// Etapa 9: agora inclui [AuthInterceptor] para bearer token + refresh automático.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();

  final tokenStorage = ref.read(tokenStorageProvider);
  final authNotifier = ref.read(authStateProvider.notifier);

  client.addAuthInterceptor(
    tokenStorage: tokenStorage,
    refreshCallback: ({
      required String accessToken,
      required String refreshToken,
    }) async {
      // Cria um datasource temporário com um client SEM o auth interceptor
      // para evitar loop infinito (refresh retornaria 401 → refresh → ...).
      final plainClient = ApiClient();
      final datasource = AuthRemoteDatasource(plainClient);
      return datasource.refresh(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    },
    onRefreshSuccess: (response) =>
        authNotifier.loginWithResponse(response),
    onRefreshFailure: () => authNotifier.logout(),
  );

  return client;
});

/// Cliente HTTP base usando Dio.
/// Etapa 9: com interceptor de auth e refresh automático.
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? kApiBaseUrl,
            connectTimeout: _kConnectTimeout,
            receiveTimeout: _kReceiveTimeout,
            headers: {
              'Accept': 'application/json',
            },
          ),
        ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: _log,
        ),
      );
    }
  }

  final Dio _dio;

  /// Adiciona o [AuthInterceptor] ao pipeline do Dio.
  /// Chamado uma vez pelo provider após construção.
  void addAuthInterceptor({
    required TokenStorage tokenStorage,
    required RefreshCallback refreshCallback,
    required OnRefreshSuccess onRefreshSuccess,
    required OnRefreshFailure onRefreshFailure,
  }) {
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshCallback: refreshCallback,
        onRefreshSuccess: onRefreshSuccess,
        onRefreshFailure: onRefreshFailure,
        dio: _dio,
      ),
    );
  }

  // ignore: avoid_print — log de desenvolvimento, será substituído por logger real
  static void _log(Object object) {
    // ignore: avoid_print
    print('[ApiClient] $object');
  }

  /// GET genérico que retorna a resposta completa.
  /// Erros do Dio são convertidos em [ApiException].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST genérico.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT genérico.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE genérico.
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
