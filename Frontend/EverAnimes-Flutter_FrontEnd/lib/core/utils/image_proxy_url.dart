import '../api/api_client.dart' show kApiBaseUrl;

/// Builds a proxied image URL via `/api/image-proxy` to avoid
/// CORS / mixed-content issues when loading external CDN images.
///
/// If the URL is null/empty or already points to the local API,
/// returns it as-is. The caller should still handle errors
/// (the proxy may return 400/408/502) and fall back to the
/// original URL when needed.
String? proxyImageUrl(String? remoteUrl) {
  if (remoteUrl == null || remoteUrl.isEmpty) return remoteUrl;

  // Already pointing at our own API — no need to proxy.
  if (remoteUrl.startsWith(kApiBaseUrl)) return remoteUrl;

  // Only proxy http(s) URLs.
  final uri = Uri.tryParse(remoteUrl);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    return remoteUrl;
  }

  return '$kApiBaseUrl/api/image-proxy?url=${Uri.encodeComponent(remoteUrl)}';
}
