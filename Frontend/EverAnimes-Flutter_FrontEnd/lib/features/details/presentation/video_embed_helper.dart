// Helper para resolver URLs de embed de vídeo de diferentes provedores.
//
// Suporta: Wistia, YouTube, Dailymotion.
// Para provedores não-embedáveis (Crunchyroll, Netflix, etc.) retorna `null`.

import '../../../core/utils/image_proxy_url.dart';

/// Resultado da resolução de embed.
class EmbedResult {
  const EmbedResult({required this.embedUrl, required this.provider});

  /// URL pronta para ser usada em um iframe.
  final String embedUrl;

  /// Nome legível do provedor (ex: 'YouTube', 'Wistia', 'Dailymotion').
  final String provider;
}

/// Tenta resolver a [url] de um episódio para uma URL de embed.
///
/// Retorna `null` quando o provedor não suporta embed (Crunchyroll, Netflix,
/// Amazon Prime Video etc.) — nesses casos, deve-se abrir em nova aba.
EmbedResult? resolveEmbedUrl(String url) {
  // --- Wistia ---
  final wistiaId = _extractWistiaId(url);
  if (wistiaId != null) {
    return EmbedResult(
      embedUrl:
          'https://fast.wistia.com/embed/iframe/$wistiaId?videoFoam=true&autoPlay=false',
      provider: 'Wistia',
    );
  }

  // --- YouTube ---
  final youtubeId = _extractYouTubeId(url);
  if (youtubeId != null) {
    return EmbedResult(
      embedUrl:
          'https://www.youtube.com/embed/$youtubeId?rel=0&modestbranding=1',
      provider: 'YouTube',
    );
  }

  // --- Dailymotion ---
  final dailymotionId = _extractDailymotionId(url);
  if (dailymotionId != null) {
    return EmbedResult(
      embedUrl: 'https://www.dailymotion.com/embed/video/$dailymotionId',
      provider: 'Dailymotion',
    );
  }

  // Provedor desconhecido ou não-embedável
  return null;
}

/// Gera um identificador único para o viewType do platform view.
///
/// Usado como chave no registro de platform views do Flutter Web para
/// garantir que cada combinação de provedor + id tenha seu próprio iframe.
String embedViewTypeId(EmbedResult embed) {
  // sanitize para usar como viewType (sem caracteres especiais)
  final sanitized = embed.embedUrl
      .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
      .substring(0, embed.embedUrl.length.clamp(0, 80));
  return 'embed-player-$sanitized';
}

// ---------------------------------------------------------------------------
// Extractors internos
// ---------------------------------------------------------------------------

/// Wistia: `*.wistia.com/medias/{id}`
String? _extractWistiaId(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('wistia.com')) return null;
    final segments = uri.pathSegments;
    final idx = segments.indexOf('medias');
    if (idx == -1 || idx + 1 >= segments.length) return null;
    final id = segments[idx + 1];
    return id.isEmpty ? null : id;
  } catch (_) {
    return null;
  }
}

/// YouTube — formatos suportados:
/// - `https://www.youtube.com/watch?v=ID`
/// - `https://youtu.be/ID`
/// - `https://www.youtube.com/embed/ID`
/// - `https://youtube.com/shorts/ID`
/// - `https://www.youtube.com/v/ID`
String? _extractYouTubeId(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.replaceAll('www.', '');

    // youtu.be/ID
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return (id != null && id.length >= 11) ? id : null;
    }

    if (host != 'youtube.com' && host != 'm.youtube.com') return null;

    // /watch?v=ID
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // /embed/ID, /v/ID, /shorts/ID
    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      final prefix = segments[0];
      if (prefix == 'embed' || prefix == 'v' || prefix == 'shorts') {
        return segments[1];
      }
    }

    return null;
  } catch (_) {
    return null;
  }
}

/// Dailymotion — formatos suportados:
/// - `https://www.dailymotion.com/video/ID`
/// - `https://dai.ly/ID`
String? _extractDailymotionId(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.replaceAll('www.', '');

    // dai.ly/ID
    if (host == 'dai.ly') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (host != 'dailymotion.com') return null;

    // /video/ID
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'video') {
      return segments[1];
    }

    return null;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Episode thumbnail resolver
// ---------------------------------------------------------------------------

/// Attempts to resolve a provider-specific thumbnail URL for the given
/// episode [url]. Falls back to [fallbackCoverUrl] (typically the anime cover)
/// when the provider is unknown or does not expose thumbnails.
///
/// The returned URL is proxied through `/api/image-proxy` to avoid CORS.
String? resolveEpisodeThumbnail(String url, {String? fallbackCoverUrl}) {
  // YouTube → https://img.youtube.com/vi/{id}/mqdefault.jpg
  final ytId = _extractYouTubeId(url);
  if (ytId != null) {
    return proxyImageUrl('https://img.youtube.com/vi/$ytId/mqdefault.jpg');
  }

  // Dailymotion → https://www.dailymotion.com/thumbnail/video/{id}
  final dmId = _extractDailymotionId(url);
  if (dmId != null) {
    return proxyImageUrl('https://www.dailymotion.com/thumbnail/video/$dmId');
  }

  // Wistia — no simple public thumbnail endpoint; use fallback.
  // Google Drive — no thumbnail endpoint; use fallback.

  // Fallback: anime cover
  if (fallbackCoverUrl != null && fallbackCoverUrl.isNotEmpty) {
    return proxyImageUrl(fallbackCoverUrl);
  }

  return null;
}
