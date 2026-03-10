import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_tokens.dart';
import 'video_embed_helper.dart';

// ---------------------------------------------------------------------------
// _viewTypeRegistry — controla quais viewTypes já foram registrados
// para evitar registros duplicados no PlatformViewRegistry.
// ---------------------------------------------------------------------------
final _registeredViewTypes = <String>{};

/// Widget genérico que embeda um vídeo via iframe (Flutter Web).
///
/// Funciona para qualquer provedor cujo [EmbedResult] tenha sido resolvido
/// pelo [resolveEmbedUrl]. O iframe aponta para [embed.embedUrl].
class EmbedPlayer extends StatefulWidget {
  const EmbedPlayer({
    super.key,
    required this.embed,
    this.aspectRatio = 16 / 9,
  });

  /// Resultado resolvido pelo [resolveEmbedUrl].
  final EmbedResult embed;

  /// Aspect ratio do container. Padrão: 16:9.
  final double aspectRatio;

  @override
  State<EmbedPlayer> createState() => _EmbedPlayerState();
}

class _EmbedPlayerState extends State<EmbedPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = _buildViewType(widget.embed);

    if (!_registeredViewTypes.contains(_viewType)) {
      _registeredViewTypes.add(_viewType);
      final embedUrl = widget.embed.embedUrl;
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final iframe = web.HTMLIFrameElement()
            ..src = embedUrl
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none'
            ..style.borderRadius = '${AppRadius.card}px'
            ..allowFullscreen = true
            ..setAttribute(
              'allow',
              'autoplay; fullscreen; encrypted-media; picture-in-picture',
            )
            ..setAttribute('loading', 'lazy');
          return iframe;
        },
      );
    }
  }

  /// Gera um viewType curto e único baseado no embedUrl.
  String _buildViewType(EmbedResult embed) {
    // Usa hashCode para manter curto e evitar problemas com caracteres.
    final hash = embed.embedUrl.hashCode.toUnsigned(32).toRadixString(16);
    return 'embed-player-${embed.provider.toLowerCase()}-$hash';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        color: AppColors.bgDeep,
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
