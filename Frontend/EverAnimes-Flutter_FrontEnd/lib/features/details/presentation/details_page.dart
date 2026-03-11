import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../core/widgets/upscalable_hero_image.dart';
import '../../../core/widgets/translatable_text.dart';
import '../../../widgets/top_header.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../features/home/widgets/hero_banner.dart'
    show StarRatingWidget, AddToListButton, CircularPlayButton;
import '../../../features/auth/domain/auth_state_provider.dart';
import '../../../features/admin/data/dtos/anime_dtos.dart'
    show AnimeCreateDto, AnimeUpdateDto;
import '../../../features/admin/domain/animes_providers.dart';
import '../data/dtos/anime_details_dto.dart';
import 'details_providers.dart';
import 'video_embed_helper.dart';

// ---------------------------------------------------------------------------
// DetailsPage -- Etapa 7
// ---------------------------------------------------------------------------

enum _DetailsTab { overview, episodes, links, similar }

class DetailsPage extends ConsumerStatefulWidget {
  const DetailsPage({
    super.key,
    required this.source,
    this.id,
    this.externalId,
  });

  final String source;
  final int? id;
  final String? externalId;

  @override
  ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends ConsumerState<DetailsPage> {
  _DetailsTab _activeTab = _DetailsTab.overview;

  @override
  Widget build(BuildContext context) {
    final params =
        (source: widget.source, id: widget.id, externalId: widget.externalId);
    final asyncDetails = ref.watch(animeDetailsProvider(params));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      extendBodyBehindAppBar: true,
      body: asyncDetails.when(
        loading: () => const _DetailsSkeleton(),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.bgBase,
          body: Padding(
            padding: const EdgeInsets.only(top: kTopHeaderHeight),
            child: ErrorView(
              error: error,
              fallbackMessage: l10n.detailsLoadError,
              onRetry: () => ref.invalidate(animeDetailsProvider(params)),
            ),
          ),
        ),
        data: (details) => _DetailsBody(
          details: details,
          heroTag:
              'anime-cover-${widget.source}-${widget.externalId ?? widget.id}',
          activeTab: _activeTab,
          onTabChange: (t) => setState(() => _activeTab = t),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailsBody
// ---------------------------------------------------------------------------

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.details,
    required this.heroTag,
    required this.activeTab,
    required this.onTabChange,
  });

  final AnimeDetailsDto details;
  final String heroTag;
  final _DetailsTab activeTab;
  final ValueChanged<_DetailsTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        // 7-A: full-bleed hero background
        _DetailsHeroBackground(
          coverUrl: details.coverUrl,
          heroTag: heroTag,
          height: screenH * 0.65,
        ),

        CustomScrollView(
          slivers: [
            // Transparent SliverAppBar with back button
            SliverAppBar(
              expandedHeight: screenH * 0.6,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.viewPaddingOf(context).top + 8,
                    left: 12,
                  ),
                  child: const _BackButton(),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 7-B: hero info section
                    _DetailsHeroSection(details: details),

                    // 7-C: tab menu
                    _DetailsTabMenu(
                      activeTab: activeTab,
                      onTabChange: onTabChange,
                    ),

                    // 7-D: tab content
                    _DetailsTabContent(
                      activeTab: activeTab,
                      details: details,
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7-A  _DetailsHeroBackground
// ---------------------------------------------------------------------------

class _DetailsHeroBackground extends StatelessWidget {
  const _DetailsHeroBackground({
    required this.coverUrl,
    required this.heroTag,
    required this.height,
  });

  final String? coverUrl;
  final String heroTag;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image
          if (coverUrl != null)
            Hero(
              tag: heroTag,
              child: UpscalableHeroImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, _) => Container(
                  color: AppColors.surface,
                ),
              ),
            )
          else
            Container(color: AppColors.surface),

          // Gradient overlay top (darken top for status bar)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgBase.withValues(alpha: 0.55),
                    Colors.transparent,
                    AppColors.bgBase.withValues(alpha: 0.20),
                    AppColors.bgBase,
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Side vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.bgBase.withValues(alpha: 0.30),
                    Colors.transparent,
                    AppColors.bgBase.withValues(alpha: 0.20),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BackButton
// ---------------------------------------------------------------------------

class _BackButton extends StatefulWidget {
  const _BackButton();

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovering
                ? AppColors.surface.withValues(alpha: 0.95)
                : AppColors.surface.withValues(alpha: 0.70),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-B  _DetailsHeroSection
// ---------------------------------------------------------------------------

class _DetailsHeroSection extends StatelessWidget {
  const _DetailsHeroSection({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide = screenW >= 800;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailsCoverCard(coverUrl: details.coverUrl),
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: _DetailsTitleBlock(details: details)),
              ],
            )
          : _DetailsTitleBlock(details: details),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailsCoverCard
// ---------------------------------------------------------------------------

class _DetailsCoverCard extends StatelessWidget {
  const _DetailsCoverCard({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        width: 160,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: coverUrl != null
              ? ProxiedImage(
                  src: coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, _) => Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.movie_outlined,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailsTitleBlock
// ---------------------------------------------------------------------------

class _DetailsTitleBlock extends ConsumerWidget {
  const _DetailsTitleBlock({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.isAuthenticated &&
        authState.role.toLowerCase() == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + admin edit
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SelectableText(
                details.title,
                style: AppTextStyles.titleHero,
                maxLines: 3,
              ),
            ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _AdminEditButton(details: details),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Add to list button — estilo banner (+ Adicionar à lista)
        AddToListButton(
          compact: false,
          details: details,
        ),
        const SizedBox(height: 10),

        _DetailsMetadataRow(details: details),
        const SizedBox(height: 6),

        // Genres
        if (details.genres.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: details.genres
                .map(
                  (g) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.40),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      g,
                      style: AppTextStyles.meta.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
        ],

        // Actions
        Row(
          children: [
            CircularPlayButton(
              size: 52,
              onTap: () => _playFirstEpisode(context, details),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailsMetadataRow  + _MetaBadge
// ---------------------------------------------------------------------------

class _DetailsMetadataRow extends StatelessWidget {
  const _DetailsMetadataRow({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (details.year != null)
          Text(
            '${details.year}',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (details.score != null) ...[
          StarRatingWidget(
            score: details.score!,
            starSize: 14,
          ),
          Text(
            details.score!.toStringAsFixed(1),
            style: AppTextStyles.body.copyWith(
              color: AppColors.star,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (details.episodeCount != null)
          _MetaBadge(label: '${details.episodeCount} eps'),
        if (details.episodeLength != null)
          _MetaBadge(label: '${details.episodeLength} min'),
        _MetaBadge(label: details.source.toUpperCase()),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceVariant, width: 0.8),
      ),
      child: Text(
        label,
        style: AppTextStyles.meta.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-C  _DetailsTabMenu
// ---------------------------------------------------------------------------

class _DetailsTabMenu extends StatelessWidget {
  const _DetailsTabMenu({
    required this.activeTab,
    required this.onTabChange,
  });

  final _DetailsTab activeTab;
  final ValueChanged<_DetailsTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (_DetailsTab.overview, l10n.adminAnimesSynopsis),
      (_DetailsTab.episodes, l10n.episodes),
      (_DetailsTab.links, l10n.links),
      (_DetailsTab.similar, l10n.similar),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs
              .map(
                (t) => _TabItem(
                  label: t.$2,
                  isActive: activeTab == t.$1,
                  onTap: () => onTabChange(t.$1),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppColors.accent
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.body.copyWith(
              color: widget.isActive
                  ? AppColors.accent
                  : _hovering
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-D  _DetailsTabContent
// ---------------------------------------------------------------------------

class _DetailsTabContent extends StatelessWidget {
  const _DetailsTabContent({
    required this.activeTab,
    required this.details,
  });

  final _DetailsTab activeTab;
  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(activeTab),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: switch (activeTab) {
            _DetailsTab.overview => _OverviewTab(details: details),
            _DetailsTab.episodes => _EpisodesTab(details: details),
            _DetailsTab.links => _LinksTab(details: details),
            _DetailsTab.similar => const _SimilarTab(),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab content widgets
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final synopsis = details.synopsis;
    if (synopsis == null || synopsis.isEmpty) {
      return Text(
        l10n.detailsEmptySynopsis,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }
    return TranslatableText(
      text: synopsis,
      style: AppTextStyles.body.copyWith(height: 1.65),
    );
  }
}

class _EpisodesTab extends StatelessWidget {
  const _EpisodesTab({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eps = details.streamingEpisodes;
    if (eps.isEmpty) {
      return Text(
        l10n.detailsEmptyEpisodes,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(eps.length, (i) {
        final ep = eps[i];
        final canEmbed = resolveEmbedUrl(ep.url) != null;
        final thumbUrl = resolveEpisodeThumbnail(
          ep.url,
          fallbackCoverUrl: details.coverUrl,
        );

        return _EpisodeThumbnailCard(
          title: ep.title,
          thumbnailUrl: thumbUrl,
          canEmbed: canEmbed,
          onTap: () {
            if (canEmbed) {
              final extId =
                  details.externalId ?? details.id?.toString() ?? '';
              context.push(
                '/watch/${details.source}/$extId?ep=$i',
              );
            } else {
              _openUrl(ep.url);
            }
          },
        );
      }),
    );
  }
}

/// Thumbnail card for a single episode — shows a 16:9 thumbnail image
/// with a semi-transparent overlay containing a play icon and the episode title.
class _EpisodeThumbnailCard extends StatefulWidget {
  const _EpisodeThumbnailCard({
    required this.title,
    required this.thumbnailUrl,
    required this.canEmbed,
    required this.onTap,
  });

  final String title;
  final String? thumbnailUrl;
  final bool canEmbed;
  final VoidCallback onTap;

  @override
  State<_EpisodeThumbnailCard> createState() => _EpisodeThumbnailCardState();
}

class _EpisodeThumbnailCardState extends State<_EpisodeThumbnailCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 220.0;
    const cardHeight = cardWidth * 9 / 16; // 16:9 aspect ratio

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              color: AppColors.surface,
              border: Border.all(
                color: _hovered
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.surfaceVariant,
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
                    width: cardWidth,
                    height: cardHeight,
                    errorBuilder: (_, e, s) => const ColoredBox(
                      color: AppColors.surface,
                      child: Center(
                        child: Icon(Icons.movie, color: AppColors.textSecondary,
                            size: 32),
                      ),
                    ),
                  )
                else
                  const ColoredBox(
                    color: AppColors.surface,
                    child: Center(
                      child: Icon(Icons.movie, color: AppColors.textSecondary,
                          size: 32),
                    ),
                  ),

                // Gradient overlay for text readability
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [
                        Color(0x00000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),

                // Play icon
                Center(
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      widget.canEmbed
                          ? Icons.play_circle_fill
                          : Icons.open_in_new,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                // Title at bottom
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
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
    );
  }
}

class _LinksTab extends StatelessWidget {
  const _LinksTab({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final links = details.externalLinks;
    if (links.isEmpty) {
      return Text(
        l10n.detailsEmptyLinks,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: links
          .map(
            (link) => ActionChip(
              avatar: const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.textSecondary,
              ),
              label: Text(link.site, style: AppTextStyles.meta),
              onPressed: () => _openUrl(link.url),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.surfaceVariant, width: 0.8),
            ),
          )
          .toList(),
    );
  }
}

class _SimilarTab extends StatelessWidget {
  const _SimilarTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.detailsSimilarSoon,
      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Abre o primeiro episódio disponível.
/// Wistia → player imersivo. Caso contrário → nova aba.
void _playFirstEpisode(BuildContext context, AnimeDetailsDto details) {
  final eps = details.streamingEpisodes;
  if (eps.isEmpty) return;

  final firstEp = eps.first;
  final isEmbeddable = resolveEmbedUrl(firstEp.url) != null;

  if (isEmbeddable) {
    final extId = details.externalId ?? details.id?.toString() ?? '';
    context.push('/watch/${details.source}/$extId?ep=0');
  } else {
    _openUrl(firstEp.url);
  }
}

// ---------------------------------------------------------------------------
// _DetailsSkeleton
// ---------------------------------------------------------------------------

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero area shimmer
            ShimmerBox(
              width: double.infinity,
              height: screenH * 0.60,
              borderRadius: 0,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ShimmerBox(height: 28, width: 280, borderRadius: 6),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Metadata chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: const [
                  ShimmerBox(height: 22, width: 50, borderRadius: 4),
                  SizedBox(width: 8),
                  ShimmerBox(height: 22, width: 70, borderRadius: 4),
                  SizedBox(width: 8),
                  ShimmerBox(height: 22, width: 60, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Synopsis lines
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ShimmerBox(
                height: 14,
                width: double.infinity,
                borderRadius: 4,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ShimmerBox(
                height: 14,
                width: double.infinity,
                borderRadius: 4,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ShimmerBox(height: 14, width: 200, borderRadius: 4),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: const [
                  ShimmerBox(height: 52, width: 52, borderRadius: 26),
                  SizedBox(width: AppSpacing.sm),
                  ShimmerBox(height: 40, width: 130, borderRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AdminEditButton — shown only for Admin users on the detail page
// ---------------------------------------------------------------------------

class _AdminEditButton extends ConsumerWidget {
  const _AdminEditButton({required this.details});

  final AnimeDetailsDto details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openEditor(context, ref),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.edit, color: AppColors.accent, size: 18),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final isLocal = details.source == 'local';

    final result = await showDialog<_AdminEditResult>(
      context: context,
      builder: (ctx) => _AdminEditDialog(
        details: details,
        isLocal: isLocal,
      ),
    );

    if (result == null) return;

    try {
      final datasource = ref.read(animesDatasourceProvider);

      if (result.isCreate) {
        // Force fresh data from API for reliable duplicate check
        ref.invalidate(animesListProvider);
        final existingLocal = await ref.read(animesListProvider.future);
        final normalizedTitle =
            result.createDto!.title.trim().toLowerCase();
        int? duplicateId;
        for (final anime in existingLocal) {
          final sameTitle = anime.title.trim().toLowerCase() == normalizedTitle;
          final sameYear = anime.year != null &&
                  result.createDto!.year != null
              ? anime.year == result.createDto!.year
              : true;
          if (sameTitle && sameYear) {
            duplicateId = anime.id;
            break;
          }
        }

        if (duplicateId != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Este anime já existe no banco local.'),
              ),
            );
          }
          return;
        }

        await datasource.create(result.createDto!);
        ref.invalidate(animesListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anime created in local DB')),
          );
        }
      } else {
        await datasource.update(result.localId!, result.updateDto!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anime updated')),
          );
          // Invalidate the details to refresh
          final params = (
            source: details.source,
            id: details.id,
            externalId: details.externalId,
          );
          ref.invalidate(animeDetailsProvider(params));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// _AdminEditResult
// ---------------------------------------------------------------------------

class _AdminEditResult {
  const _AdminEditResult.create(AnimeCreateDto dto)
      : createDto = dto,
        updateDto = null,
        localId = null;
  const _AdminEditResult.update(int id, AnimeUpdateDto dto)
      : createDto = null,
        updateDto = dto,
        localId = id;

  final AnimeCreateDto? createDto;
  final AnimeUpdateDto? updateDto;
  final int? localId;

  bool get isCreate => createDto != null;
}

// ---------------------------------------------------------------------------
// _AdminEditDialog
// ---------------------------------------------------------------------------

class _AdminEditDialog extends StatefulWidget {
  const _AdminEditDialog({required this.details, required this.isLocal});

  final AnimeDetailsDto details;
  final bool isLocal;

  @override
  State<_AdminEditDialog> createState() => _AdminEditDialogState();
}

class _AdminEditDialogState extends State<_AdminEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _synopsisCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _coverUrlCtrl;
  String? _status;

  @override
  void initState() {
    super.initState();
    final d = widget.details;
    _titleCtrl = TextEditingController(text: d.title);
    _synopsisCtrl = TextEditingController(text: d.synopsis ?? '');
    _yearCtrl = TextEditingController(text: d.year?.toString() ?? '');
    _scoreCtrl = TextEditingController(text: d.score?.toString() ?? '');
    _coverUrlCtrl = TextEditingController(text: d.coverUrl ?? '');
    _status = null; // status not available in AnimeDetailsDto
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _yearCtrl.dispose();
    _scoreCtrl.dispose();
    _coverUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCreate = !widget.isLocal;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCreate ? 'Create Local Anime' : 'Edit Anime',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCreate)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will create a new entry in the local database.',
                          style: TextStyle(
                              color: Colors.orangeAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildField('Title *', _titleCtrl),
              const SizedBox(height: AppSpacing.sm),

              _buildField('Synopsis', _synopsisCtrl, maxLines: 4),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(child: _buildField('Year', _yearCtrl)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _buildField('Score', _scoreCtrl)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Status dropdown
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: AppColors.surface,
                decoration: _inputDecoration('Status'),
                style: const TextStyle(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'RELEASING', child: Text('Releasing')),
                  DropdownMenuItem(value: 'FINISHED', child: Text('Finished')),
                  DropdownMenuItem(
                      value: 'NOT_YET_RELEASED',
                      child: Text('Not Yet Released')),
                  DropdownMenuItem(
                      value: 'CANCELLED', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'HIATUS', child: Text('Hiatus')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildField('Cover URL', _coverUrlCtrl),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          icon: Icon(isCreate ? Icons.add : Icons.save, size: 16),
          label: Text(isCreate ? 'Create' : 'Save'),
          onPressed: _onSave,
        ),
      ],
    );
  }

  TextField _buildField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.textSecondary.withAlpha(80)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  void _onSave() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final year = int.tryParse(_yearCtrl.text);
    final score = double.tryParse(_scoreCtrl.text);
    final synopsis =
        _synopsisCtrl.text.trim().isEmpty ? null : _synopsisCtrl.text.trim();
    final coverUrl =
        _coverUrlCtrl.text.trim().isEmpty ? null : _coverUrlCtrl.text.trim();

    if (widget.isLocal) {
      Navigator.of(context).pop(
        _AdminEditResult.update(
          widget.details.id!,
          AnimeUpdateDto(
            title: title,
            synopsis: synopsis,
            year: year,
            status: _status,
            score: score,
            coverUrl: coverUrl,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop(
        _AdminEditResult.create(
          AnimeCreateDto(
            title: title,
            synopsis: synopsis,
            year: year,
            status: _status,
            score: score,
            coverUrl: coverUrl,
          ),
        ),
      );
    }
  }
}
