import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dtos/auth_dtos.dart';
import '../data/token_storage.dart';
import 'auth_providers.dart';

/// Provider do estado de autenticação — Etapa 8 (real).
final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

/// Estado de autenticação.
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.email,
    this.role = 'user',
  });

  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? email;
  final String role;

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? email,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Inicia não-autenticado; a persistência é restaurada via [restoreSession].
    return const AuthState();
  }

  TokenStorage get _storage => ref.read(tokenStorageProvider);

  /// Processa a resposta de login: extrai claims do JWT, salva tokens
  /// no storage e atualiza o state.
  Future<void> loginWithResponse(AuthResponseDto response) async {
    final claims = _decodeJwtPayload(response.accessToken);

    await _storage.save(
      accessToken: response.accessToken,
      accessExpiry: response.accessTokenExpiresAtUtc,
      refreshToken: response.refreshToken,
      refreshExpiry: response.refreshTokenExpiresAtUtc,
    );

    state = AuthState(
      isAuthenticated: true,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      email: claims['email'] as String?,
      role: _extractRole(claims),
    );
  }

  /// Tenta restaurar a sessão a partir do armazenamento local.
  /// Chamado no startup do app.
  /// Etapa 9: se o access token expirou, tenta refresh automático.
  Future<void> restoreSession() async {
    final stored = await _storage.readAll();
    if (stored == null) return;

    final accessExpired = stored.accessExpiry != null &&
        stored.accessExpiry!.isBefore(DateTime.now().toUtc());

    if (!accessExpired) {
      // Access token ainda válido — restaura normalmente.
      final claims = _decodeJwtPayload(stored.accessToken);
      state = AuthState(
        isAuthenticated: true,
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
        email: claims['email'] as String?,
        role: _extractRole(claims),
      );
      return;
    }

    // Access token expirado — tenta refresh se possível.
    if (stored.refreshToken == null) {
      await _storage.clear();
      return;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.refresh(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken!,
      );
      await loginWithResponse(response);
    } catch (_) {
      // Refresh falhou — limpa tudo.
      await _storage.clear();
    }
  }

  /// Limpa tokens e reseta o estado.
  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState();
  }

  /// Extrai a role do mapa de claims JWT.
  /// O .NET usa `ClaimTypes.Role` que gera a chave com URI completa:
  /// `http://schemas.microsoft.com/ws/2008/06/identity/claims/role`
  /// Tentamos a chave curta 'role' primeiro, depois a URI completa.
  static String _extractRole(Map<String, dynamic> claims) {
    const roleUri =
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
    final role = claims['role'] ?? claims[roleUri];
    return (role as String?) ?? 'user';
  }

  /// Decodifica o payload de um JWT (sem verificar assinatura).
  /// Retorna mapa de claims.
  static Map<String, dynamic> _decodeJwtPayload(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return {};
      // base64url → base64 → bytes → JSON
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
