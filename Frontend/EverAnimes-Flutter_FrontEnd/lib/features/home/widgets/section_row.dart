import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/widgets/hero_banner.dart' show StarRatingWidget, AddToListButton;

// ─────────────────────────────────────────────────────────────────────────────
// SectionRow — Etapa 5
//
// Widget reutilizável para qualquer seção horizontal de posters.
// Estrutura: SectionHeader (5-A) → HorizontalPosterList (5-B)
//   → PosterCard (5-C) + PosterHoverOverlay (5-D) + NavArrowButton (5-E)
// ─────────────────────────────────────────────────────────────────────────────

const double _kPosterBaseW = 130.0;
const double _kPosterBaseH = 195.0; // proporção 2:3

/// Escala responsiva idêntica ao mini_carousel.
double _posterW(double viewW) =>
    (_kPosterBaseW * (viewW / 900.0).clamp(1.0, 1.6));
double _posterH(double viewW) =>
    (_kPosterBaseH * (viewW / 900.0).clamp(1.0, 1.6));

// Helper de interpolação linear com clamp.
double _lerpClamp(double a, double b, double t) =>
    a + (b - a) * t.clamp(0.0, 1.0);

// ─────────────────────────────────────────────────────────────────────────────
// SectionRow — raiz pública (reutilizado nas Etapas 6, 7 etc.)
// ─────────────────────────────────────────────────────────────────────────────

class SectionRow extends StatelessWidget {
  const SectionRow({
    super.key,
    required this.title,
    this.sectionIcon,
    required this.items,
    this.onSeeAll,
  });

  final String title;
  final IconData? sectionIcon;
  final List<AnimeItemDto> items;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 5-A
        _SectionHeader(
          title: title,
          sectionIcon: sectionIcon,
          onSeeAll: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.sm),
        // 5-B
        HorizontalPosterList(items: items),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-A SectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.sectionIcon,
    this.onSeeAll,
  });

  final String title;
  final IconData? sectionIcon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : 64),
      child: Row(
        children: [
          if (sectionIcon != null) ...[
            Icon(sectionIcon, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(title, style: AppTextStyles.sectionTitle),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 0),
              ),
              child: Text(
                AppLocalizations.of(context)!.viewAll,
                style: TextStyle(fontSize: 12, letterSpacing: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-B HorizontalPosterList
// ─────────────────────────────────────────────────────────────────────────────

class HorizontalPosterList extends StatefulWidget {
  const HorizontalPosterList({super.key, required this.items});

  final List<AnimeItemDto> items;

  @override
  State<HorizontalPosterList> createState() => _HorizontalPosterListState();
}

class _HorizontalPosterListState extends State<HorizontalPosterList>
    with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  bool _hovered = false;
  int? _hoveredIndex;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  // ── Auto-scroll ────────────────────────────────────────────────
  Timer? _autoScrollTimer;
  bool _autoScrollForward = true;
  bool _isMobile = false;

  /// Velocidade do auto-scroll: pixels por tick.
  /// Increased to compensate for the lower tick rate (~20 fps).
  static const double _autoScrollSpeed = 5.0;

  /// Intervalo do tick (~20 fps — suficiente para scroll suave, reduz CPU 
  /// significativamente vs 60fps original).
  static const Duration _autoScrollInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addObserver(this);
    // O timer só inicia em desktop; _setMobile() o cancela quando necessário.
    _startAutoScroll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _scroll.removeListener(_updateArrows);
    _scroll.dispose();
    super.dispose();
  }

  /// Pausa o timer quando o app vai para segundo plano (aba escondida no web,
  /// app minimizado em mobile) e retoma quando volta ao foco.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isMobile) _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  /// Cancela ou inicia o timer conforme a plataforma muda (ex: redimensionamento
  /// que coloca/retira o layout do modo mobile).
  void _setMobile(bool isMobile) {
    if (_isMobile == isMobile) return;
    _isMobile = isMobile;
    if (_isMobile) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, _autoScrollTick);
  }

  void _autoScrollTick(Timer _) {
    // Desabilitado no mobile ou quando o mouse está sobre o carousel.
    if (_isMobile || _hovered) return;
    if (!_scroll.hasClients) return;

    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;

    final current = _scroll.offset;
    if (_autoScrollForward) {
      if (current >= max) {
        _autoScrollForward = false;
      } else {
        _scroll.jumpTo((current + _autoScrollSpeed).clamp(0.0, max));
      }
    } else {
      if (current <= 0) {
        _autoScrollForward = true;
      } else {
        _scroll.jumpTo((current - _autoScrollSpeed).clamp(0.0, max));
      }
    }
  }

  void _updateArrows() {
    final canLeft = _scroll.offset > 8;
    final canRight =
        _scroll.offset < _scroll.position.maxScrollExtent - 8;
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
          _setMobile(viewW < AppBreakpoints.mobile);
          final vignetteW = _isMobile ? 32.0 : 80.0;
          final pW = _posterW(viewW);
          final pH = _posterH(viewW);
          final stride = pW + AppSpacing.xs;
          final count = widget.items.length;
          final totalW = AppSpacing.md * 2.0 +
              count * pW +
              (count - 1) * AppSpacing.xs;
          // Headroom vertical: 30% extra para a expansão de 25% para cima/baixo
          final outerH = pH * 1.30;

          return SizedBox(
            height: outerH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Cards: SingleScrollView + Stack z-ordenado ──────────
                // O AnimatedBuilder fica DENTRO do SingleChildScrollView
                // para que apenas o conteúdo reconstrua a cada frame de
                // scroll, sem recriar o próprio ScrollView.
                SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder: (ctx, _) {
                      final scrollOff =
                          _scroll.hasClients ? _scroll.offset : 0.0;

                      // Z-order: card hovado vai por último → pinta por cima
                      final indices =
                          List.generate(count, (i) => i);
                      if (_hoveredIndex != null) {
                        indices.remove(_hoveredIndex!);
                        indices.add(_hoveredIndex!);
                      }

                      return SizedBox(
                        width: totalW,
                        height: outerH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: indices.map((index) {
                            final isHov = index == _hoveredIndex;
                            final normalLeft =
                                AppSpacing.md + index * stride;

                            // Skip perspective on mobile — just use 1.0 scale/opacity
                            double perspScale;
                            double perspOpacity;
                            if (_isMobile) {
                              perspScale = 1.0;
                              perspOpacity = 1.0;
                            } else {
                              final centerX = normalLeft +
                                  pW / 2 -
                                  scrollOff;
                              final dist =
                                  (centerX - viewW / 2).abs();
                              final norm = dist / (viewW * 0.46);
                              perspScale = isHov
                                  ? 1.0
                                  : _lerpClamp(1.0, 0.72, norm);
                              perspOpacity = isHov
                                  ? 1.0
                                  : _lerpClamp(1.0, 0.40, norm);
                            }

                            // Hover: 1.7× largura, 1.25× altura — desktop only
                            final tw = (isHov && !_isMobile)
                                ? pW * 1.7
                                : pW * perspScale;
                            final th = (isHov && !_isMobile)
                                ? pH * 1.25
                                : pH * perspScale;

                            // Centraliza dentro do outerH
                            final leftPos =
                                normalLeft + (pW - tw) / 2;
                            final topPos = (outerH - th) / 2;

                            return AnimatedPositioned(
                              key: ValueKey(index),
                              duration:
                                  const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              left: leftPos,
                              top: topPos,
                              width: tw,
                              height: th,
                              child: RepaintBoundary(
                                child: FadeTransition(
                                  opacity: AlwaysStoppedAnimation(
                                      perspOpacity),
                                  child: PosterCard(
                                    anime: widget.items[index],
                                    onHoverChanged: (hovered) {
                                      setState(() {
                                        _hoveredIndex =
                                            hovered ? index : null;
                                      });
                                    },
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

                // ── Vignette esquerda ───────────────────────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: vignetteW,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.bgBase, Color(0x00202020)],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Vignette direita ────────────────────────────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: vignetteW,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [AppColors.bgBase, Color(0x00202020)],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── NavArrowButton esquerdo ─────────────────────────────
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
                        onPressed: () => _scrollBy(
                            -(pW + AppSpacing.xs) * 5),
                      ),
                    ),
                  ),

                // ── NavArrowButton direito ──────────────────────────────
                if (_canScrollRight)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: NavArrowButton(
                        direction: NavArrowDirection.right,
                        transparent: true,
                        onPressed: () =>
                            _scrollBy((pW + AppSpacing.xs) * 5),
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
// 5-C PosterCard
// ─────────────────────────────────────────────────────────────────────────────

class PosterCard extends StatefulWidget {
  const PosterCard({
    super.key,
    required this.anime,
    required this.onHoverChanged,
  });

  final AnimeItemDto anime;
  /// Callback disparado quando o mouse entra/sai do card.
  /// O pai usa para coordenar scale e z-order na perspectiva 3D.
  final void Function(bool hovered) onHoverChanged;

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final heroTag =
        'poster-${widget.anime.source}-${widget.anime.externalId ?? widget.anime.id}';
    final isMobile = AppBreakpoints.isMobile(context);

    return Semantics(
      label: AppLocalizations.of(context)!.watchAnime(widget.anime.title),
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: isMobile ? null : (_) {
          setState(() => _hovered = true);
          widget.onHoverChanged(true);
        },
        onExit: isMobile ? null : (_) {
          setState(() => _hovered = false);
          widget.onHoverChanged(false);
        },
        child: GestureDetector(
          onTap: () {
            final id = widget.anime.externalId ?? '${widget.anime.id}';
            context.push('/anime/${widget.anime.source}/$id');
          },
          // ClipRRect with Clip.hardEdge instead of AnimatedContainer
          // — avoids implicit animation overhead and uses cheaper clipping.
          child: ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius:
                BorderRadius.circular(_hovered ? 6.0 : 0.0),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Imagem do poster
                Hero(
                  tag: heroTag,
                  child: _buildCover(),
                ),

                // Desktop: info persistente (título + nota) na base
                if (!isMobile)
                  _PosterBaseInfo(
                    anime: widget.anime,
                    visible: !_hovered,
                  ),

                // Overlay com info — visível no hover (ou always on mobile)
                _PosterHoverOverlay(
                  anime: widget.anime,
                  visible: _hovered || isMobile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (widget.anime.coverUrl?.isNotEmpty != true) {
      return Container(
        color: AppColors.surface,
        child: const Icon(Icons.movie_outlined,
            size: 40, color: AppColors.textSecondary),
      );
    }
    return ProxiedImage(
      src: widget.anime.coverUrl!,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, st) => Container(
        color: AppColors.surface,
        child: const Icon(Icons.broken_image_outlined,
            size: 32, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-D′ PosterBaseInfo — título + nota sempre visíveis no desktop (sem hover)
// ─────────────────────────────────────────────────────────────────────────────

class _PosterBaseInfo extends StatelessWidget {
  const _PosterBaseInfo({required this.anime, required this.visible});

  final AnimeItemDto anime;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0xDD000000),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anime.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                    shadows: [
                      Shadow(color: Color(0x99000000), blurRadius: 4),
                    ],
                  ),
                ),
                if (anime.score != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StarRatingWidget(score: anime.score!, starSize: 8),
                      const SizedBox(width: 3),
                      Text(
                        anime.score!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-D PosterHoverOverlay
// ─────────────────────────────────────────────────────────────────────────────

class _PosterHoverOverlay extends StatelessWidget {
  const _PosterHoverOverlay({
    required this.anime,
    required this.visible,
  });

  final AnimeItemDto anime;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Escurece topo (título) e base (info); centro livre para play
            stops: [0.0, 0.28, 0.72, 1.0],
            colors: [
              Color(0xCC000000), // topo semi-opaco
              Color(0x00000000), // centro transparente
              Color(0x44000000), // fade inferior
              Color(0xF0000000), // base quase opaca
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Título no topo ───────────────────────────────────
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Text(
                anime.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  shadows: [
                    Shadow(color: Color(0x99000000), blurRadius: 4),
                  ],
                ),
              ),
            ),

            // ── Ícone play centralizado — hidden on mobile ──────
            if (!isMobile)
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.52),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.88),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.accent, // vermelho EverAnimes
                    size: 28,
                  ),
                ),
              ),

            // ── Info na base (scaled up for expanded hover) ────────
            Positioned(
              left: AppSpacing.sm + 2,
              right: AppSpacing.sm + 2,
              bottom: AppSpacing.sm + 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ano + Estrelas + Nota  — hide year on mobile
                  Row(
                    children: [
                      if (anime.year != null && !isMobile) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${anime.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (anime.score != null) ...[
                        StarRatingWidget(
                            score: anime.score!, starSize: 12),
                        const SizedBox(width: 4),
                        Text(
                          anime.score!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // + Minha Lista — compact icon-only to fit poster card
                  AddToListButton(anime: anime, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-E NavArrowButton  (Netflix-style: full-height gradient panel)
// ─────────────────────────────────────────────────────────────────────────────

enum NavArrowDirection { left, right }

/// Seta de navegação full-height com gradient lateral estilo Netflix.
/// Deve ser colocado dentro de um [Stack] com fill de altura.
class NavArrowButton extends StatefulWidget {
  const NavArrowButton({
    super.key,
    required this.direction,
    required this.onPressed,
    this.transparent = false,
  });

  final NavArrowDirection direction;
  final VoidCallback onPressed;
  /// Quando true, o botão não mostra fundo (nem no hover).
  /// Ideal para carroséis menores onde o fundo escuro fica inválido.
  final bool transparent;

  @override
  State<NavArrowButton> createState() => _NavArrowButtonState();
}

class _NavArrowButtonState extends State<NavArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.direction == NavArrowDirection.left;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        // Use DecoratedBox + SizedBox instead of AnimatedContainer
        // to avoid implicit animation cost on every hover toggle.
        child: SizedBox(
          width: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.transparent
                  ? Colors.transparent
                  : (_hovered
                      ? Colors.black.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.only(
                topLeft: isLeft
                    ? const Radius.circular(AppRadius.card)
                    : Radius.zero,
                bottomLeft: isLeft
                    ? const Radius.circular(AppRadius.card)
                    : Radius.zero,
                topRight: isLeft
                    ? Radius.zero
                    : const Radius.circular(AppRadius.card),
                bottomRight: isLeft
                    ? Radius.zero
                    : const Radius.circular(AppRadius.card),
              ),
            ),
            child: Center(
              child: Icon(
                isLeft
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: _hovered ? 1.0 : 0.75),
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
