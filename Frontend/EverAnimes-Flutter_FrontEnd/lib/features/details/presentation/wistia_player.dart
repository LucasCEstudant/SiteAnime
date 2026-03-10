import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_tokens.dart';

// ---------------------------------------------------------------------------
// WistiaPlayer — Etapa 9.1
//
// Embeda um vídeo Wistia via iframe nativo do browser (Flutter Web).
//
// Uso:
//   WistiaPlayer(mediaId: 'zippt59v17')
//
// Helpers públicos:
//   wistiaMediaId(url)  — extrai o media ID de uma URL Wistia, ou null.
//   isWistiaUrl(url)    — true se for URL do domínio *.wistia.com/medias/.
// ---------------------------------------------------------------------------

/// Extrai o media ID de uma URL Wistia como
/// `https://everanimes.wistia.com/medias/zippt59v17`
/// Retorna `null` se a URL não for Wistia.
String? wistiaMediaId(String url) {
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

/// Retorna `true` se [url] for de um domínio Wistia com path `/medias/`.
bool isWistiaUrl(String url) => wistiaMediaId(url) != null;

// ---------------------------------------------------------------------------
// _viewTypeRegistry — controla quais viewTypes já foram registrados
// para evitar registros duplicados no PlatformViewRegistry.
// ---------------------------------------------------------------------------
final _registeredViewTypes = <String>{};

/// Widget que embeda um vídeo Wistia usando HtmlElementView (somente web).
///
/// Exibe um <iframe> responsivo apontando para:
///   `https://fast.wistia.com/embed/iframe/{mediaId}`
///
/// Usa a estratégia nativa do Flutter Web (dart:ui_web + package:web).
class WistiaPlayer extends StatefulWidget {
  const WistiaPlayer({
    super.key,
    required this.mediaId,
    this.aspectRatio = 16 / 9,
  });

  final String mediaId;

  /// Aspect ratio do container do player. Padrão: 16:9.
  final double aspectRatio;

  @override
  State<WistiaPlayer> createState() => _WistiaPlayerState();
}

class _WistiaPlayerState extends State<WistiaPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'wistia-player-${widget.mediaId}';

    if (!_registeredViewTypes.contains(_viewType)) {
      _registeredViewTypes.add(_viewType);
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final iframe = web.HTMLIFrameElement()
            ..src =
                'https://fast.wistia.com/embed/iframe/${widget.mediaId}?videoFoam=true&autoPlay=false'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none'
            ..style.borderRadius = '${AppRadius.card}px'
            ..allowFullscreen = true
            ..setAttribute('allow', 'autoplay; fullscreen')
            ..setAttribute('loading', 'lazy');
          return iframe;
        },
      );
    }
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

// ---------------------------------------------------------------------------
// WistiaPlayerCard — wrapper com cabeçalho e botão de fechar
// ---------------------------------------------------------------------------

/// Wrapper em torno do WistiaPlayer com título do episódio, borda temática
/// e botão para fechar/minimizar.
class WistiaPlayerCard extends StatelessWidget {
  const WistiaPlayerCard({
    super.key,
    required this.mediaId,
    required this.title,
    required this.onClose,
  });

  final String mediaId;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the player at 720 px on wide screens so 16:9 never overflows.
        final maxW = constraints.maxWidth.isInfinite
            ? 720.0
            : constraints.maxWidth.clamp(0.0, 720.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: maxW,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.bgDeep,
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_filled,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.meta.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  label: 'Fechar player',
                  button: true,
                  child: GestureDetector(
                    onTap: onClose,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Player
          WistiaPlayer(mediaId: mediaId),
        ],
      ),
    );
  }
}
