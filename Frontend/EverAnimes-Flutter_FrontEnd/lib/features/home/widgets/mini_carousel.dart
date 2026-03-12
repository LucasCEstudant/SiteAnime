import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_state_provider.dart';
import '../../user_animes/data/dtos/user_anime_dtos.dart';
import '../../user_animes/presentation/user_animes_providers.dart';
import 'home_skeletons.dart';
import 'section_row.dart' show NavArrowButton, NavArrowDirection;

// ─────────────────────────────────────────────────────────────────────────────
// MiniCarousel — Etapa 4
//
// Faixa horizontal compacta (h = 120) com miniaturas de poster da temporada
// atual, posicionada logo abaixo do HeroBanner. Cada card é clicável e
// dispara uma animação de hover sutil via AnimatedContainer + scale.
// ─────────────────────────────────────────────────────────────────────────────

const double _kCardBaseSize = 80.0;

/// Escala responsiva: 1× até 900 px de largura do carousel,
/// 1.6× a partir de 1536 px (ultrawide 2560 com margem 20%).
double _miniCardSz(double viewW) =>
    (_kCardBaseSize * (viewW / 900.0).clamp(1.0, 1.6));

/// Altura total do MiniCarousel (label ~40 + cards) — exportado para home_page.
double miniCarouselHeightFor(double carouselW) =>
    40.0 + _miniCardSz(carouselW);

// Helper de interpolação linear com clamp embutido.
double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);

/// Faixa compacta com miniaturas de poster da lista do usuário.
///
/// Visível apenas quando o usuário está autenticado e possui itens na lista.
/// Quando não autenticado ou lista vazia, o widget colapsa para [SizedBox.shrink].
class MiniCarousel extends ConsumerWidget {
  const MiniCarousel({super.key});

  /// Query padrão: primeira página, sem filtros.
  static const _kQuery = (
    status: null as String?,
    year: null as int?,
    page: 1,
    pageSize: 20,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final asyncPage = ref.watch(userAnimesPageProvider(_kQuery));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Faixa de posters ────────────────────────────────────────────
        asyncPage.when(
          loading: () => const SizedBox(
            height: _kCardBaseSize,
            child: MiniCarouselSkeleton(),
          ),
          error: (err, _) => const SizedBox.shrink(),
          data: (page) {
            final items = page.items
                .where((a) => a.coverUrl?.isNotEmpty == true)
                .map(_toAnimeItemDto)
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: _ContinueWatchingLabel(),
                ),
                _MiniCarouselStrip(items: items),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Converte [UserAnimeDto] → [AnimeItemDto] para reaproveitar o strip.
  static AnimeItemDto _toAnimeItemDto(UserAnimeDto ua) {
    return AnimeItemDto(
      source: ua.externalProvider ?? 'local',
      id: ua.animeId,
      externalId: ua.externalId,
      title: ua.title,
      year: ua.year,
      score: ua.score,
      coverUrl: ua.coverUrl,
    );
  }
}

/// Label localizada "Continue Assistindo" extraída para receber context.
class _ContinueWatchingLabel extends StatelessWidget {
  const _ContinueWatchingLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.continueWatching,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniCarouselStrip — lista horizontal com setas Netflix-style
// ─────────────────────────────────────────────────────────────────────────────

class _MiniCarouselStrip extends StatefulWidget {
  const _MiniCarouselStrip({required this.items});
  final List<AnimeItemDto> items;

  @override
  State<_MiniCarouselStrip> createState() => _MiniCarouselStripState();
}

class _MiniCarouselStripState extends State<_MiniCarouselStrip> {
  final ScrollController _scroll = ScrollController();
  bool _hovered = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateArrows);
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    final canLeft = _scroll.offset > 8;
    final canRight = _scroll.offset < _scroll.position.maxScrollExtent - 8;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollBy(double delta) {
    _scroll.animateTo(
      (_scroll.offset + delta).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final viewW = constraints.maxWidth;
          final cardSz = _miniCardSz(viewW);
          final itemStride = cardSz + AppSpacing.xs;
          final contentWidth =
              widget.items.length * itemStride - AppSpacing.xs;
          // expandPad: (1.25−1)/2 × cardSz + folga
          final kExpandPad = cardSz * 0.15;
          return SizedBox(
            height: cardSz,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Lista com efeito de perspectiva 3D ────────────────────
                // ClipRect corta apenas na horizontal (borda do viewport) mas
                // deixa os 30 px verticais livres para a expansão do hover.
                ClipRect(
                  clipper: _HorizontalOnlyClipper(
                    verticalPad: kExpandPad,
                  ),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    // Clip.none: não corta o último card na borda do viewport.
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: AnimatedBuilder(
                      animation: _scroll,
                      builder: (ctx, _) {
                        final scrollOffset =
                            _scroll.hasClients ? _scroll.offset : 0.0;
                        final isMobile = viewW < 600;

                        // Gera dados de perspectiva para cada card
                        // Skip perspective on mobile — saves per-card math.
                        final cardData =
                            List.generate(widget.items.length, (index) {
                          if (isMobile) {
                            return (
                              index: index,
                              scale: 1.0,
                              opacity: 1.0,
                            );
                          }
                          final cardCenterX = AppSpacing.md +
                              index * itemStride +
                              cardSz / 2 -
                              scrollOffset;
                          final dist = (cardCenterX - viewW / 2).abs();
                          final norm = dist / (viewW * 0.44);
                          return (
                            index: index,
                            scale: _lerp(1.0, 0.70, norm),
                            opacity: _lerp(1.0, 0.38, norm),
                          );
                        });

                        // Reordena: card com hover vai para o fim → pintado por cima
                        final sorted = List.of(cardData);
                        if (_hoveredIndex != null) {
                          final hi = sorted
                              .indexWhere((e) => e.index == _hoveredIndex);
                          if (hi >= 0) sorted.add(sorted.removeAt(hi));
                        }

                        return SizedBox(
                          width: contentWidth,
                          height: cardSz,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: sorted.map((e) {
                              // Chave estável baseada na identidade do item (não
                              // no índice posicional), para que inserções no início
                              // da lista não causem reuso de estado incorreto.
                              final item = widget.items[e.index];
                              final stableKey = item.id?.toString()
                                  ?? item.externalId
                                  ?? 'idx_${e.index}';
                              return Positioned(
                                key: ValueKey(stableKey),
                                left: e.index * itemStride,
                                top: 0,
                                width: cardSz,
                                height: cardSz,
                                child: RepaintBoundary(
                                  child: Transform.scale(
                                    scale: e.scale,
                                    alignment: Alignment.center,
                                    // FadeTransition with AlwaysStoppedAnimation uses
                                    // OpacityLayer (cheap GPU blend) instead of Opacity's
                                    // saveLayer (expensive offscreen buffer).
                                    child: FadeTransition(
                                      opacity: AlwaysStoppedAnimation(e.opacity),
                                      child: MiniPosterCard(
                                          anime: widget.items[e.index],
                                          cardSize: cardSz,
                                          onHoverChanged: (hovered) =>
                                            setState(() {
                                          _hoveredIndex =
                                              hovered ? e.index : null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Seta esquerda ────────────────────────────────────────
                if (_canScrollLeft)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: NavArrowButton(
                        direction: NavArrowDirection.left,
                        transparent: true,
                        onPressed: () =>
                            _scrollBy(-(cardSz + AppSpacing.xs) * 3),
                      ),
                    ),
                  ),

                // ── Seta direita ─────────────────────────────────────────
                if (_canScrollRight)
                  Positioned(
                    right: -24,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: NavArrowButton(
                        direction: NavArrowDirection.right,
                        transparent: true,
                        onPressed: () =>
                            _scrollBy((cardSz + AppSpacing.xs) * 3),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4-A MiniPosterCard
// ─────────────────────────────────────────────────────────────────────────────

/// Miniatura de poster 80×120 com hover scale e navegação para detalhes.
class MiniPosterCard extends StatefulWidget {
  const MiniPosterCard({
    super.key,
    required this.anime,
    required this.cardSize,
    this.onHoverChanged,
  });

  final AnimeItemDto anime;
  final double cardSize;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<MiniPosterCard> createState() => _MiniPosterCardState();
}

class _MiniPosterCardState extends State<MiniPosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)!.watchAnime(widget.anime.title),
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          widget.onHoverChanged?.call(true);
        },
        onExit: (_) {
          setState(() => _hovered = false);
          widget.onHoverChanged?.call(false);
        },
        child: GestureDetector(
          onTap: () {
            final id = widget.anime.externalId ?? '${widget.anime.id}';
            context.push('/anime/${widget.anime.source}/$id');
          },
          child: AnimatedScale(
            scale: _hovered ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: widget.cardSize,
              height: widget.cardSize,
              // Use ClipRRect with Clip.hardEdge instead of
              // AnimatedContainer with Clip.antiAlias — cheaper on GPU.
              child: ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.circular(
                    _hovered ? AppRadius.card : 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster image
                    ProxiedImage(
                      src: widget.anime.coverUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: widget.anime.title,
                      errorBuilder: (ctx, err, st) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),

                    // Hover overlay — gradient + play + título
                    // No mobile, mostra título/gradiente sempre (sem hover).
                    AnimatedOpacity(
                      opacity: (_hovered || AppBreakpoints.isMobile(context))
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.30, 0.70, 1.0],
                            colors: [
                              Color(0xCC000000), // topo escuro
                              Color(0x00000000), // centro livre
                              Color(0x33000000), // fade inferior
                              Color(0xDD000000), // base escura
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Título no topo
                            Positioned(
                              left: 5,
                              right: 5,
                              top: 5,
                              child: Text(
                                widget.anime.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Play icon centralizado — hidden on mobile
                            if (_hovered)
                              Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black
                                        .withValues(alpha: 0.52),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.88),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clipper que corta horizontalmente nas bordas do widget mas estende
// verticalmente em [verticalPad] para acomodar a expansão de hover dos cards.
// ─────────────────────────────────────────────────────────────────────────────
class _HorizontalOnlyClipper extends CustomClipper<Rect> {
  const _HorizontalOnlyClipper({
    required this.verticalPad,
  });
  final double verticalPad;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        0,
        -verticalPad,
        size.width,
        size.height + verticalPad,
      );

  @override
  bool shouldReclip(_HorizontalOnlyClipper old) =>
      old.verticalPad != verticalPad;
}
