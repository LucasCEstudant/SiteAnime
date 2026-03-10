import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/upscalable_hero_image.dart';
import '../../../features/details/presentation/details_providers.dart';
import '../../../features/details/presentation/video_embed_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../presentation/home_banner_providers.dart';
import '../presentation/home_providers.dart';
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
    // Tenta resolver banners secundários via API.
    final asyncBanners = ref.watch(resolvedSecondaryBannersProvider);
    // Fallback: animes locais.
    final asyncLocal = ref.watch(localAnimesProvider);

    return asyncBanners.when(
      loading: () => const FeaturedSectionSkeleton(),
      error: (_, __) => _buildFromLocal(asyncLocal),
      data: (banners) {
        if (banners.isEmpty) return _buildFromLocal(asyncLocal);
        final animeList = banners.map((b) => b.anime).toList();
        return _buildCarousel(animeList);
      },
    );
  }

  Widget _buildFromLocal(AsyncValue<List<AnimeItemDto>> asyncLocal) {
    final Widget? content = asyncLocal.whenOrNull(
      data: (items) {
        final candidates =
            items.where((a) => a.coverUrl?.isNotEmpty == true).toList();
        if (candidates.isEmpty) return null;
        // Usa os últimos 3 animes locais como carrossel, ou 1 se só tiver 1
        final carouselItems =
            candidates.length > 3 ? candidates.sublist(candidates.length - 3) : [candidates.last];
        return _buildCarousel(carouselItems);
      },
    );

    if (asyncLocal.isLoading) return const FeaturedSectionSkeleton();
    if (content == null) return const SizedBox.shrink();
    return content;
  }

  Widget _buildCarousel(List<AnimeItemDto> animes) {
    // Garante auto-play ativo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoPlay(animes.length);
    });

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

          // ── 6-C Info Panel (esquerda / full-width on mobile) ────────
          Positioned(
            left: isMobile ? AppSpacing.md : 64,
            top: 0,
            bottom: 0,
            right: isMobile ? AppSpacing.md : null,
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

          // ── 6-E Side Menu — hidden on mobile ───────────────────────
          if (!isMobile)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _FeaturedSideMenu(
                anime: anime,
                activeTab: activeTab,
                onTabChange: onTabChange,
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
    return UpscalableHeroImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
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
          child: Text(
            synopsis,
            maxLines: 5,
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

  /// 5.2 – Episódios mostra lista real compacta
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
        // Mostra até 6 episódios em chips compactos horizontais
        final shown = eps.take(6).toList();
        return SizedBox(
          key: const ValueKey('episodes'),
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: List.generate(shown.length, (i) {
              final ep = shown[i];
              final canEmbed = resolveEmbedUrl(ep.url) != null;
              return ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  canEmbed ? Icons.play_circle_outline : Icons.open_in_new,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  ep.title,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  if (canEmbed) {
                    final id =
                        anime.externalId ?? '${anime.id}';
                    context.push('/watch/${anime.source}/$id?ep=$i');
                  } else {
                    launchUrl(Uri.parse(ep.url),
                        mode: LaunchMode.externalApplication);
                  }
                },
                backgroundColor:
                    AppColors.surfaceVariant.withValues(alpha: 0.6),
                side: BorderSide.none,
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
  });

  final AnimeItemDto anime;
  final _SideTab activeTab;
  final ValueChanged<_SideTab> onTabChange;

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
        padding: const EdgeInsets.only(right: AppSpacing.xl),
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
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SideTabButton> createState() => _SideTabButtonState();
}

class _SideTabButtonState extends State<_SideTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.isActive || _hovered;
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
