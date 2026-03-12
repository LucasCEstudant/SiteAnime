import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../features/auth/data/token_storage.dart';

/// In-memory cache + rate-limit-safe service for the
/// `POST /api/images/upscale` endpoint.
///
/// The service:
/// - caches upscaled bytes by original URL (LRU, max [_kMaxCacheEntries])
/// - avoids duplicate in-flight requests for the same URL
/// - respects 429 backoff (single retry with 3 s delay)
/// - never calls the endpoint when the user is not authenticated
/// - reuses a single [Dio] instance
class ImageUpscaleService {
  ImageUpscaleService({
    required TokenStorage tokenStorage,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? kApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          // Upscale can take several minutes through the full chain.
          receiveTimeout: const Duration(seconds: 480),
          responseType: ResponseType.bytes,
        ));

  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// Max cached entries before the oldest is evicted (LRU).
  static const _kMaxCacheEntries = 20;

  /// Completed upscale results (insertion-ordered for LRU eviction).
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  /// In-flight requests so we don't duplicate them.
  final Map<String, Future<Uint8List?>> _inflight = {};

  /// Returns cached bytes if already upscaled; otherwise `null`.
  Uint8List? getCached(String imageUrl) => _cache[imageUrl];

  /// Request upscale for [imageUrl]. Returns upscaled PNG bytes, or
  /// `null` on any error (auth, rate-limit, timeout, etc.).
  ///
  /// Safe to call multiple times for the same URL — deduplicates.
  Future<Uint8List?> upscale(String imageUrl) async {
    if (_cache.containsKey(imageUrl)) return _cache[imageUrl];
    if (_inflight.containsKey(imageUrl)) return _inflight[imageUrl];

    final future = _doUpscale(imageUrl);
    _inflight[imageUrl] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(imageUrl);
    }
  }

  Future<Uint8List?> _doUpscale(String imageUrl) async {
    // Need a valid access token.
    final stored = await _tokenStorage.readAll();
    if (stored == null) return null;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.post<List<int>>(
          '/api/images/upscale',
          data: {'imageUrl': imageUrl},
          options: Options(
            headers: {
              'Authorization': 'Bearer ${stored.accessToken}',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final bytes = Uint8List.fromList(response.data!);
          _putCache(imageUrl, bytes);
          return bytes;
        }
        return null;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // 429 Too Many Requests — wait 3 s and retry once.
        if (status == 429 && attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 3));
          continue;
        }
        // Any other error — give up.
        return null;
      }
    }
    return null;
  }

  /// Insert into cache with LRU eviction when exceeding max entries.
  void _putCache(String key, Uint8List value) {
    _cache.remove(key);
    _cache[key] = value;
    while (_cache.length > _kMaxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

/// Riverpod provider for the singleton [ImageUpscaleService].
final imageUpscaleServiceProvider = Provider<ImageUpscaleService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ImageUpscaleService(tokenStorage: tokenStorage);
});
