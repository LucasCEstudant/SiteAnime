import 'package:dio/dio.dart';

/// Exceção customizada para erros de API.
/// Converte erros do Dio em mensagens legíveis.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiExceptionType.unknown,
  });

  /// Factory a partir de [DioException].
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Tempo de conexão esgotado. Tente novamente.',
          type: ApiExceptionType.timeout,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Não foi possível conectar ao servidor. '
              'Verifique sua conexão de rede.',
          type: ApiExceptionType.network,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        // 429 Too Many Requests — rate limit atingido.
        if (statusCode == 429) {
          return const ApiException(
            message: 'Muitas tentativas. Aguarde um momento e tente novamente.',
            statusCode: 429,
            type: ApiExceptionType.rateLimit,
          );
        }
        final detail = _extractDetail(e.response);
        return ApiException(
          message: detail ?? 'Erro do servidor ($statusCode).',
          statusCode: statusCode,
          type: ApiExceptionType.server,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Requisição cancelada.',
          type: ApiExceptionType.cancelled,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Certificado de segurança inválido.',
          type: ApiExceptionType.unknown,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: e.message ?? 'Erro desconhecido.',
          type: ApiExceptionType.unknown,
        );
    }
  }

  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  /// Tenta extrair "detail" do ProblemDetails (RFC 7807) retornado pela API.
  static String? _extractDetail(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      // ValidationProblemDetails: junta mensagens do campo "errors".
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final messages = errors.values
            .expand((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .toList();
        if (messages.isNotEmpty) return messages.join(' ');
      }
      return data['detail'] as String? ?? data['title'] as String?;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($type): $message [status=$statusCode]';
}

enum ApiExceptionType {
  timeout,
  network,
  server,
  rateLimit,
  cancelled,
  unknown,
}
