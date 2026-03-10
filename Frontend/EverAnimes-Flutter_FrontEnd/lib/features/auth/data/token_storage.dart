import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chaves usadas no SharedPreferences.
const _kAccessToken = 'auth_access_token';
const _kRefreshToken = 'auth_refresh_token';
const _kAccessExpiry = 'auth_access_expiry';
const _kRefreshExpiry = 'auth_refresh_expiry';

/// Provider singleton do token storage.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Armazena e recupera tokens de autenticação usando SharedPreferences.
/// Etapa 8: persistência simples — sem criptografia (web não tem keychain).
class TokenStorage {
  /// Salva os tokens após login/refresh.
  Future<void> save({
    required String accessToken,
    required DateTime accessExpiry,
    String? refreshToken,
    DateTime? refreshExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kAccessExpiry, accessExpiry.toIso8601String());
    if (refreshToken != null) {
      await prefs.setString(_kRefreshToken, refreshToken);
    }
    if (refreshExpiry != null) {
      await prefs.setString(_kRefreshExpiry, refreshExpiry.toIso8601String());
    }
  }

  /// Lê o access token salvo, ou `null` se não existir.
  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  /// Lê o refresh token salvo, ou `null` se não existir.
  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  /// Lê todos os dados salvos.
  Future<StoredTokens?> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_kAccessToken);
    if (accessToken == null) return null;

    return StoredTokens(
      accessToken: accessToken,
      accessExpiry: DateTime.tryParse(prefs.getString(_kAccessExpiry) ?? ''),
      refreshToken: prefs.getString(_kRefreshToken),
      refreshExpiry: DateTime.tryParse(prefs.getString(_kRefreshExpiry) ?? ''),
    );
  }

  /// Remove todos os tokens (logout).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kAccessExpiry);
    await prefs.remove(_kRefreshExpiry);
  }
}

/// Dados armazenados localmente.
class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    this.accessExpiry,
    this.refreshToken,
    this.refreshExpiry,
  });

  final String accessToken;
  final DateTime? accessExpiry;
  final String? refreshToken;
  final DateTime? refreshExpiry;
}
