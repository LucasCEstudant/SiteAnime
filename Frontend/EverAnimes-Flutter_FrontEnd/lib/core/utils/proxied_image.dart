import 'package:flutter/material.dart';

import 'image_proxy_url.dart';

/// Drop-in replacement for [Image.network] that first tries to load the
/// image through `/api/image-proxy` (avoids CORS / mixed-content on Web).
///
/// If the proxied request fails, it falls back to the original URL
/// transparently.  All standard [Image.network] parameters are forwarded.
class ProxiedImage extends StatefulWidget {
  const ProxiedImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.errorBuilder,
    this.webHtmlElementStrategy,
  });

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final String? semanticLabel;
  final ImageErrorWidgetBuilder? errorBuilder;
  final WebHtmlElementStrategy? webHtmlElementStrategy;

  @override
  State<ProxiedImage> createState() => _ProxiedImageState();
}

class _ProxiedImageState extends State<ProxiedImage> {
  bool _proxyFailed = false;

  String get _url {
    if (_proxyFailed) return widget.src;
    return proxyImageUrl(widget.src) ?? widget.src;
  }

  @override
  void didUpdateWidget(ProxiedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _proxyFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _url,
      // ValueKey força um _ImageState fresco sempre que a URL muda,
      // evitando que a imagem anterior fique visível enquanto a nova carrega.
      key: ValueKey(_url),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel,
      webHtmlElementStrategy:
          widget.webHtmlElementStrategy ?? WebHtmlElementStrategy.prefer,
      errorBuilder: (ctx, err, st) {
        // If proxy URL failed, retry with original URL once.
        if (!_proxyFailed && _url != widget.src) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _proxyFailed = true);
          });
          // Temporarily show a blank box while we flip to fallback.
          return SizedBox(width: widget.width, height: widget.height);
        }
        // Both proxy and original failed — show error widget.
        return widget.errorBuilder?.call(ctx, err, st) ??
            const SizedBox.shrink();
      },
    );
  }
}
