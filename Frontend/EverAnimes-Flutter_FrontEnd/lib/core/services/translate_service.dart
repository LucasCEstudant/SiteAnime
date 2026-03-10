import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TranslateService — cache em memória, deduplicação de requests, fallback
//
// • POST /api/translate  {text, targetLang, sourceLang?, format?}
// • Resposta: {text, provider, detectedLanguage, latencyMs, cacheHit}
// • Erros tratados: 400 (texto inválido), 429 (rate limit), 502 (provider)
// ─────────────────────────────────────────────────────────────────────────────

/// Provider singleton do [TranslateService].
final translateServiceProvider = Provider<TranslateService>((ref) {
  return TranslateService(ref.read(apiClientProvider));
});

class TranslateService {
  TranslateService(this._api);

  final ApiClient _api;

  /// Cache em memória: chave = "$sourceLang|$targetLang|$text"
  final _cache = HashMap<String, String>();

  /// Mapa de requests em andamento para deduplicação via Completer.
  final _inflight = HashMap<String, Completer<String>>();

  /// Número máximo de entradas no cache para não estourar memória.
  static const int _maxCacheEntries = 500;

  /// Gera chave de cache para um trio (source, target, text).
  String _cacheKey(String text, String targetLang, String? sourceLang) =>
      '${sourceLang ?? 'auto'}|$targetLang|$text';

  /// Se o idioma de destino é igual ao idioma do texto, não há necessidade
  /// de traduzir (ex.: sinopse já em pt-BR e locale == pt-BR).
  bool _isSameLocale(String targetLang, String? sourceLang) =>
      sourceLang != null &&
      sourceLang.toLowerCase() == targetLang.toLowerCase();

  /// Traduz [text] para [targetLang].
  ///
  /// Retorna a tradução cacheada se disponível; caso contrário dispara
  /// o POST à API. Se já existir uma request idêntica em andamento,
  /// reutiliza o mesmo [Completer] (deduplicação).
  ///
  /// Em caso de erro (rede, 429, 502…), retorna `null` para que o widget
  /// exiba o texto original como fallback.
  Future<String?> translate({
    required String text,
    required String targetLang,
    String? sourceLang,
    String format = 'text',
  }) async {
    if (text.trim().isEmpty) return null;

    // Mesmo idioma → sem necessidade de tradução.
    if (_isSameLocale(targetLang, sourceLang)) return text;

    final key = _cacheKey(text, targetLang, sourceLang);

    // 1. Cache hit → retorno imediato.
    if (_cache.containsKey(key)) return _cache[key];

    // 2. Request idêntica em andamento → reutiliza.
    if (_inflight.containsKey(key)) return _inflight[key]!.future;

    // 3. Nova request.
    final completer = Completer<String>();
    _inflight[key] = completer;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/translate',
        data: {
          'text': text,
          'targetLang': targetLang,
          if (sourceLang != null) 'sourceLang': sourceLang,
          'format': format,
        },
      );

      final translated = response.data?['text'] as String? ?? text;

      // Evita crescimento ilimitado do cache.
      if (_cache.length >= _maxCacheEntries) {
        // Remove a primeira metade das entradas (FIFO simplificado).
        final keysToRemove = _cache.keys.take(_maxCacheEntries ~/ 2).toList();
        for (final k in keysToRemove) {
          _cache.remove(k);
        }
      }

      _cache[key] = translated;
      completer.complete(translated);
      return translated;
    } on ApiException catch (_) {
      // Falha de tradução: retorna null → widget mostra texto original.
      completer.complete(text);
      return null;
    } catch (_) {
      completer.complete(text);
      return null;
    } finally {
      _inflight.remove(key);
    }
  }

  /// Limpa todo o cache (útil ao trocar de idioma, por exemplo).
  void clearCache() {
    _cache.clear();
    // Não cancela inflight — elas completarão normalmente.
  }
}
