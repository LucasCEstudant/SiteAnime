// DTOs para o fluxo de autenticação (`/api/auth`).

/// Request body para `POST /api/auth/login`.
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Request body para `POST /api/auth/register`.
/// Campos iguais ao login (email + password).
class RegisterRequestDto {
  const RegisterRequestDto({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Request body para `POST /api/auth/refresh`.
class RefreshTokenRequestDto {
  const RefreshTokenRequestDto({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}

/// Resposta de `POST /api/auth/login`, `register` e `refresh`.
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    this.refreshToken,
    this.refreshTokenExpiresAtUtc,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAtUtc;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAtUtc;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAtUtc:
          DateTime.parse(json['accessTokenExpiresAtUtc'] as String),
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiresAtUtc: json['refreshTokenExpiresAtUtc'] != null
          ? DateTime.parse(json['refreshTokenExpiresAtUtc'] as String)
          : null,
    );
  }
}
