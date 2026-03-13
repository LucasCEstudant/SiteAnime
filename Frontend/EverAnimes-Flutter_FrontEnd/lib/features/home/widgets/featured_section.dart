import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../core/widgets/translatable_text.dart';
import '../../../features/details/presentation/details_providers.dart';
import '../../../features/details/presentation/video_embed_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../presentation/home_banner_providers.dart';
import 'hero_banner.dart' show StarRatingWidget, AddToListButton, CircularPlayButton;
import 'home_skeletons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FeaturedExpandedSection — Etapa 6
//
// Bloco cinematográfico de destaque (~500px). Lê o seasonNowProvider e exibe
// um anime de índice configurável como "Em Destaque", com:
//   6-A  FeaturedBackgroundImage   — imagem full-bleed
//   6-B  FeaturedOverlay           — gradientes lateral+inferior
//   6-C  FeaturedInfoPanel         — título/meta/botões (esquerda)
//   6-D  FeaturedCloseButton       — X no topo direito (colapsa a seção)
//   6-E  FeaturedSideMenu          — abas à direita (Overview/Episódios/…)
// ─────────────────────────────────────────────────────────────────────────────

const double _kFeaturedHeight = 500;

// ─── Raiz pública ─────────────────────────────────────────────────────────────

class FeaturedExpandedSection extends ConsumerStatefulWidget {
  const FeaturedExpandedSection({super.key});

  @override
  ConsumerState<FeaturedExpandedSection> createState() =>
      _FeaturedExpandedSectionState();
}

class _FeaturedExpandedSectionState
    extends ConsumerState<FeaturedExpandedSection>
    with SingleTickerProviderStateMixin {
  _SideTab _activeTab = _SideTab.overview;
  int _currentIndex = 0;
  bool _hovering = false;
  bool _userInteracted = false;
  Timer? _autoPlayTimer;
  /// Guarda a última quantidade de itens usada para iniciar o auto-play.
  /// O timer só é reiniciado quando o count muda — evita restart a cada rebuild.
  int? _lastAutoPlayCount;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int itemCount) {
    _autoPlayTimer?.cancel();
    if (itemCount <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_hovering || _userInteracted || !mounted) return;
      final next = (_currentIndex + 1) % itemCount;
      _goToPage(next, itemCount);
    });
  }

  void _goToPage(int index, int totalCount) {
    if (!_pageController.hasClients) return;
    setState(() {
      _currentIndex = index;
      _activeTab = _SideTab.overview;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPrev(int totalCount) {
    _userInteracted = true;
    _autoPlayTimer?.cancel();
    final prev = (_currentIndex - 1 + totalCount) % totalCount;
    _goToPage(prev, totalCount);
  }

  void _onNext(int totalCount) {
    _userInteracted = true;
    _autoPlayTimer?.cancel();
    final next = (_currentIndex + 1) % totalCount;
    _goToPage(next, totalCount);
  }

  @override
  Widget build(BuildContext context) {
    // featuredAnimesProvider: tenta banners secundários e só busca animes
    // locais como fallback se não houver banners — evita chamada desnecessária
    // a GET /api/animes quando banners estão configurados.
    final asyncAnimes = ref.watch(featuredAnimesProvider);

    return asyncAnimes.when(
      loading: () => const FeaturedSectionSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (animes) {
        if (animes.isEmpty) return const SizedBox.shrink();
        return _buildCarousel(animes);
      },
    );
  }

  Widget _buildCarousel(List<AnimeItemDto> animes) {
    // Reinicia o timer apenas quando o número de itens muda (primeiro render
    // incluído). Evita cancelar + recriar o timer em cada rebuild desnecessário.
    if (_lastAutoPlayCount != animes.length) {
      _lastAutoPlayCount = animes.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startAutoPlay(animes.length);
      });
    }

    final isMobile = AppBreakpoints.isMobile(context);
    final sectionHeight = isMobile ? 350.0 : _kFeaturedHeight;

    return MouseRegion(
      onEnter: (_) => _hovering = true,
      onExit: (_) {
        _hovering = false;
        _userInteracted = false;
        _startAutoPlay(animes.length);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(
          height: sectionHeight,
          width: double.infinity,
          child: Stack(
            children: [
              // ── PageView de banners ──
              PageView.builder(
                controller: _pageController,
                itemCount: animes.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final anime = animes[index];
                  return _FeaturedContent(
                    anime: anime,
                    activeTab: index == _currentIndex
                        ? _activeTab
                        : _SideTab.overview,
                    onTabChange: (t) => setState(() => _activeTab = t),
                  );
                },
              ),

              // ── Seta esquerda ──
              if (animes.length > 1)
                Positioned(
                  left: isMobile ? 4 : AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      icon: Icons.chevron_left,
                      onTap: () => _onPrev(animes.length),
                    ),
                  ),
                ),

              // ── Seta direita ──
              if (animes.length > 1)
                Positioned(
                  right: isMobile ? 4 : AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      icon: Icons.chevron_right,
                      onTap: () => _onNext(animes.length),
                    ),
                  ),
                ),

              // ── Indicadores de página ──
              if (animes.length > 1)
                Positioned(
                  bottom: AppSpacing.md,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(animes.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentIndex ? 20 : 8,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i == _currentIndex
                              ? AppColors.accent
                              : AppColors.textSecondary
                                  .withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _FeaturedContent ─────────────────────────────────────────────────────────

class _FeaturedContent extends StatelessWidget {
  const _FeaturedContent({
    required this.anime,
    required this.activeTab,
    required this.onTabChange,
  });

  final AnimeItemDto anime;
  final _SideTab activeTab;
  final ValueChanged<_SideTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sectionHeight = isMobile ? 350.0 : _kFeaturedHeight;

    return SizedBox(
      height: sectionHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 6-A Background Image ────────────────────────────────────
          _FeaturedBackgroundImage(coverUrl: anime.coverUrl!),

          // ── 6-B Overlay gradients ───────────────────────────────────
          const _FeaturedOverlay(),

          // ── 6-C Info Panel (esquerda / constrained on mobile) ──────
          Positioned(
            left: isMobile ? AppSpacing.sm : 64,
            top: 0,
            bottom: 0,
            right: isMobile ? 56 : null,
            width: isMobile ? null : 380,
            child: _FeaturedInfoPanel(
              anime: anime,
              activeTab: activeTab,
            ),
          ),

          // ── 6-F Play Button (centro-direita) — hidden on mobile ──────
          if (!isMobile)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircularPlayButton(
                  onTap: () {
                    final id = anime.externalId ?? '${anime.id}';
                    // Abre direto no player imersivo (episódio 1)
                    context.push('/watch/${anime.source}/$id?ep=0');
                  },
                  size: 56,
                ),
              ),
            ),

          // ── 6-E Side Menu (right column — both mobile and desktop) ──
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _FeaturedSideMenu(
              anime: anime,
              activeTab: activeTab,
              onTabChange: onTabChange,
              compact: isMobile,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6-A FeaturedBackgroundImage
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedBackgroundImage extends StatelessWidget {
  const _FeaturedBackgroundImage({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    // Limit decode resolution to device logical pixels × DPR.
    // Prevents oversized decodes that waste GPU memory on weak devices.
    final mq = MediaQuery.of(context);
    final dpr = mq.devicePixelRatio.clamp(1.0, 3.0);
    final decodeWidth = (mq.size.width * dpr).toInt();

    return ProxiedImage(
      src: coverUrl,
      fit: BoxFit.cover,
      cacheWidth: decodeWidth,
      errorBuilder: (ctx, err, st) =>
          const ColoredBox(color: AppColors.bgDeep),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6-B FeaturedOverlay
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedOverlay extends StatelessWidget {
  const _FeaturedOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente inferior
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.25, 1.0],
              colors: [Color(0x00000000), Color(0xD9000000)],
            ),
          ),
        ),
        // Gradiente lateral esquerdo (painel de info)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.0, 0.65],
              colors: [Color(0xFF000000), Color(0x00000000)],
            ),
          ),
        ),
        // Gradiente lateral direito (menu lateral)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              stops: [0.0, 0.35],
              colors: [Color(0xB3000000), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6-C FeaturedInfoPanel
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedInfoPanel extends StatelessWidget {
  const _FeaturedInfoPanel({
    required this.anime,
    required this.activeTab,
  });

  final AnimeItemDto anime;
  final _SideTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge "EM DESTAQUE"
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                AppLocalizations.of(context)!.homeFeaturedBadge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Título
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleHero.copyWith(fontSize: 28),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Metadata: ano + estrelas + score
            Row(
              children: [
                if (anime.year != null)
                  Text(
                    '${anime.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (anime.year != null && anime.score != null)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('·',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                if (anime.score != null)
                  StarRatingWidget(score: anime.score!, starSize: 14),
                if (anime.score != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    anime.score!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.star,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Conteúdo da aba ativa
            _TabContent(anime: anime, tab: activeTab),

            const SizedBox(height: AppSpacing.lg),

            // Botões de ação
            Row(
              children: [
                AddToListButton(anime: anime),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () {
                    final id = anime.externalId ?? '${anime.id}';
                    context.push('/anime/${anime.source}/$id');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(AppLocalizations.of(context)!.homeDetails,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conteúdo dinâmico da aba ──────────────────────────────────────────────

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.anime, required this.tab});

  final AnimeItemDto anime;
  final _SideTab tab;

  DetailsParams get _params => (
        source: anime.source,
        id: anime.id,
        externalId: anime.externalId,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildTabBody(context, ref, tab),
    );
  }

  Widget _buildTabBody(BuildContext context, WidgetRef ref, _SideTab tab) {
    switch (tab) {
      case _SideTab.overview:
        return _buildOverview(context, ref);
      case _SideTab.episodes:
        return _buildEpisodes(context, ref);
      case _SideTab.similar:
        return SizedBox(
          key: const ValueKey('similar'),
          width: double.infinity,
          child: Text(
            AppLocalizations.of(context)!.homeSimilarDev,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        );
      case _SideTab.links:
        return _buildLinks(context, ref);
    }
  }

  /// 5.1 – Overview mostra sinopse real
  Widget _buildOverview(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetails = ref.watch(animeDetailsProvider(_params));
    return asyncDetails.when(
      loading: () => SizedBox(
        key: const ValueKey('overview-loading'),
        width: double.infinity,
        child: Text(
          l10n.homeLoadingSynopsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      error: (_, _) => SizedBox(
        key: const ValueKey('overview-error'),
        width: double.infinity,
        child: Text(
          l10n.homeErrorSynopsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      data: (details) {
        final synopsis = details.synopsis;
        if (synopsis == null || synopsis.isEmpty) {
          return SizedBox(
            key: const ValueKey('overview-empty'),
            width: double.infinity,
            child: Text(
              l10n.homeEmptySynopsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return SizedBox(
          key: const ValueKey('overview'),
          width: double.infinity,
          child: TranslatableText(
            text: synopsis,
            maxLines: AppBreakpoints.isMobile(context) ? 3 : 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        );
      },
    );
  }

  /// 5.2 – Episódios mostra lista real com thumbnails
  Widget _buildEpisodes(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetails = ref.watch(animeDetailsProvider(_params));
    return asyncDetails.when(
      loading: () => SizedBox(
        key: const ValueKey('episodes-loading'),
        child: Text(
          l10n.homeLoadingEpisodes,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      error: (_, _) => SizedBox(
        key: const ValueKey('episodes-error'),
        child: Text(
          l10n.homeErrorEpisodes,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      data: (details) {
        final eps = details.streamingEpisodes;
        if (eps.isEmpty) {
          return SizedBox(
            key: const ValueKey('episodes-empty'),
            child: Text(
              l10n.homeEmptyEpisodes,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        // Mostra até 4 episódios com thumbnail
        final shown = eps.take(4).toList();
        final isMobile = AppBreakpoints.isMobile(context);
        return SizedBox(
          key: const ValueKey('episodes'),
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: List.generate(shown.length, (i) {
              final ep = shown[i];
              final canEmbed = resolveEmbedUrl(ep.url) != null;
              final thumbUrl = resolveEpisodeThumbnail(
                ep.url,
                fallbackCoverUrl: details.coverUrl,
              );

              return _FeaturedEpisodeThumbnail(
                title: ep.title,
                thumbnailUrl: thumbUrl,
                canEmbed: canEmbed,
                width: isMobile ? 140.0 : 160.0,
                onTap: () {
                  if (canEmbed) {
                    final id = anime.externalId ?? '${anime.id}';
                    context.push('/watch/${anime.source}/$id?ep=$i');
                  } else {
                    launchUrl(Uri.parse(ep.url),
                        mode: LaunchMode.externalApplication);
                  }
                },
              );
            }),
          ),
        );
      },
    );
  }

  /// 5.4 – Links mostra links externos reais
  Widget _buildLinks(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDetails = ref.watch(animeDetailsProvider(_params));
    return asyncDetails.when(
      loading: () => SizedBox(
        key: const ValueKey('links-loading'),
        child: Text(
          l10n.homeLoadingLinks,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      error: (_, _) => SizedBox(
        key: const ValueKey('links-error'),
        child: Text(
          l10n.homeErrorLinks,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      data: (details) {
        final links = details.externalLinks;
        if (links.isEmpty) {
          return SizedBox(
            key: const ValueKey('links-empty'),
            child: Text(
              l10n.homeEmptyLinks,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return SizedBox(
          key: const ValueKey('links'),
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: links.map((link) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.open_in_new,
                    size: 14, color: AppColors.textSecondary),
                label: Text(
                  link.site,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () => launchUrl(Uri.parse(link.url),
                    mode: LaunchMode.externalApplication),
                backgroundColor:
                    AppColors.surfaceVariant.withValues(alpha: 0.6),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeaturedEpisodeThumbnail — mini thumbnail card for episodes in featured
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedEpisodeThumbnail extends StatefulWidget {
  const _FeaturedEpisodeThumbnail({
    required this.title,
    required this.thumbnailUrl,
    required this.canEmbed,
    required this.onTap,
    this.width = 160.0,
  });

  final String title;
  final String? thumbnailUrl;
  final bool canEmbed;
  final VoidCallback onTap;
  final double width;

  @override
  State<_FeaturedEpisodeThumbnail> createState() =>
      _FeaturedEpisodeThumbnailState();
}

class _FeaturedEpisodeThumbnailState extends State<_FeaturedEpisodeThumbnail> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.width * 9 / 16;
    final isMobile = AppBreakpoints.isMobile(context);

    return MouseRegion(
      onEnter: isMobile ? null : (_) => setState(() => _hovered = true),
      onExit: isMobile ? null : (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && !isMobile ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            width: widget.width,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              color: AppColors.surface,
              border: Border.all(
                color: _hovered
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.surfaceVariant.withValues(alpha: 0.4),
                width: _hovered ? 1.5 : 0.8,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail image
                if (widget.thumbnailUrl != null)
                  ProxiedImage(
                    src: widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, _) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.movie_outlined,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  )
                else
                  Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.movie_outlined,
                        color: AppColors.textSecondary, size: 20),
                  ),

                // Gradient overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),

                // Play icon
                Center(
                  child: Icon(
                    widget.canEmbed
                        ? Icons.play_circle_outline
                        : Icons.open_in_new,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                    size: 24,
                  ),
                ),

                // Title at bottom
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 4,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      shadows: [
                        Shadow(color: Color(0xBB000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carousel Navigation Arrow
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselArrow extends StatefulWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CarouselArrow> createState() => _CarouselArrowState();
}

class _CarouselArrowState extends State<_CarouselArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.85)
                : AppColors.overlayDark.withValues(alpha: 0.6),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6-E FeaturedSideMenu
// ─────────────────────────────────────────────────────────────────────────────

enum _SideTab { overview, episodes, similar, links }

class _FeaturedSideMenu extends StatelessWidget {
  const _FeaturedSideMenu({
    required this.anime,
    required this.activeTab,
    required this.onTabChange,
    this.compact = false,
  });

  final AnimeItemDto anime;
  final _SideTab activeTab;
  final ValueChanged<_SideTab> onTabChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (_SideTab.overview, l10n.overview, Icons.article_outlined),
      (_SideTab.episodes, l10n.episodes, Icons.play_circle_outline),
      (_SideTab.similar, l10n.similar, Icons.grid_view_rounded),
      (_SideTab.links, l10n.links, Icons.link_rounded),
    ];
    return Center(
      child: Padding(
        padding: EdgeInsets.only(right: compact ? AppSpacing.xs : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: tabs.map((entry) {
            final (tab, label, icon) = entry;
            final isActive = activeTab == tab;
            return _SideTabButton(
              label: label,
              icon: icon,
              isActive: isActive,
              onTap: () => onTabChange(tab),
              compact: compact,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SideTabButton extends StatefulWidget {
  const _SideTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_SideTabButton> createState() => _SideTabButtonState();
}

class _SideTabButtonState extends State<_SideTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || _hovered;

    if (widget.compact) {
      // Mobile: icon-only vertical buttons
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Tooltip(
            message: widget.label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.surfaceVariant.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.btn),
                border: widget.isActive
                    ? Border.all(color: AppColors.accent, width: 1)
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: highlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // Desktop: icon + label
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.surfaceVariant.withValues(alpha: 0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.btn),
            border: widget.isActive
                ? Border.all(color: AppColors.accent, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: highlighted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: highlighted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
