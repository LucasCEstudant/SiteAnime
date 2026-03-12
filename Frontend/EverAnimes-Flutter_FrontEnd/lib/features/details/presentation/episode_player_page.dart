import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../data/dtos/anime_details_dto.dart';
import 'details_providers.dart';
import 'embed_player.dart';
import 'video_embed_helper.dart';

/// Tela imersiva de player de episódio — experiência streaming premium.
///
/// - Embeda vídeos de Wistia, YouTube e Dailymotion no player interno.
/// - Para links não-embeddáveis (Crunchyroll, Netflix etc.) abre em nova aba.
/// - Navegação prev/next entre episódios.
/// - Layout escuro, cinemático, inspirado em plataformas de streaming.
class EpisodePlayerPage extends ConsumerStatefulWidget {
  const EpisodePlayerPage({
    super.key,
    required this.source,
    this.id,
    this.externalId,
    this.episodeIndex = 0,
  });

  final String source;
  final int? id;
  final String? externalId;
  final int episodeIndex;

  @override
  ConsumerState<EpisodePlayerPage> createState() => _EpisodePlayerPageState();
}

class _EpisodePlayerPageState extends ConsumerState<EpisodePlayerPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.episodeIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final params = (
      source: widget.source,
      id: widget.id,
      externalId: widget.externalId,
    );
    final asyncDetails = ref.watch(animeDetailsProvider(params));

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: asyncDetails.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
              const SizedBox(height: 12),
              Text(
                l10n.playerLoadError,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
                style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        data: (details) => _PlayerBody(
          details: details,
          source: widget.source,
          animeIdentifier: widget.source == 'local'
              ? '${widget.id}'
              : (widget.externalId ?? ''),
          currentIndex: _currentIndex,
          onEpisodeChange: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PlayerBody — layout principal do player
// ---------------------------------------------------------------------------

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.details,
    required this.source,
    required this.animeIdentifier,
    required this.currentIndex,
    required this.onEpisodeChange,
  });

  final String source;
  final String animeIdentifier;

  final AnimeDetailsDto details;
  final int currentIndex;
  final ValueChanged<int> onEpisodeChange;

  @override
  Widget build(BuildContext context) {
    final eps = details.streamingEpisodes;
    if (eps.isEmpty) {
      return _buildEmpty(context);
    }

    final safeIndex = currentIndex.clamp(0, eps.length - 1);
    final episode = eps[safeIndex];
    final embed = resolveEmbedUrl(episode.url);
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide = screenW >= 900;

    if (embed == null) {
      // Provedor não-embedável (Crunchyroll, Netflix etc.): abre em nova aba
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openExternal(episode.url);
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return Column(
      children: [
        // ── Top bar ─────────────────────────────────────────────────
        _TopBar(
          animeTitle: details.title,
          episodeTitle: episode.title,
          safeIndex: safeIndex,
          totalEpisodes: eps.length,
          source: source,
          animeIdentifier: animeIdentifier,
        ),

        // ── Main content ────────────────────────────────────────────
        Expanded(
          child: isWide
              ? _buildWideLayout(context, embed, episode, eps, safeIndex)
              : _buildNarrowLayout(context, embed, episode, eps, safeIndex),
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    EmbedResult embed,
    AnimeStreamingEpisodeDto episode,
    List<AnimeStreamingEpisodeDto> eps,
    int safeIndex,
  ) {
    return Row(
      children: [
        // Player area (left, takes most space)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Player
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: EmbedPlayer(
                        key: ValueKey('player-${embed.embedUrl}'),
                        embed: embed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Nav controls
                _EpisodeNavControls(
                  currentIndex: safeIndex,
                  totalEpisodes: eps.length,
                  onPrev: safeIndex > 0
                      ? () => onEpisodeChange(safeIndex - 1)
                      : null,
                  onNext: safeIndex < eps.length - 1
                      ? () => onEpisodeChange(safeIndex + 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
        // Episode list sidebar (right)
        SizedBox(
          width: 300,
          child: _EpisodeSidebar(
            episodes: eps,
            currentIndex: safeIndex,
            fallbackCoverUrl: details.coverUrl,
            onSelect: onEpisodeChange,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    EmbedResult embed,
    AnimeStreamingEpisodeDto episode,
    List<AnimeStreamingEpisodeDto> eps,
    int safeIndex,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: EmbedPlayer(
              key: ValueKey('player-${embed.embedUrl}'),
              embed: embed,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Nav controls
          _EpisodeNavControls(
            currentIndex: safeIndex,
            totalEpisodes: eps.length,
            onPrev: safeIndex > 0
                ? () => onEpisodeChange(safeIndex - 1)
                : null,
            onNext: safeIndex < eps.length - 1
                ? () => onEpisodeChange(safeIndex + 1)
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Episode list (vertical)
          Text(
            l10n.episodes,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(eps.length, (i) {
            final ep = eps[i];
            final isActive = i == safeIndex;
            return _EpisodeListTile(
              episode: ep,
              index: i,
              isActive: isActive,
              fallbackCoverUrl: details.coverUrl,
              onTap: () => onEpisodeChange(i),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.playerEmptyEpisodes,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TopBar — barra superior escura com voltar, títulos e info
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.animeTitle,
    required this.episodeTitle,
    required this.safeIndex,
    required this.totalEpisodes,
    required this.source,
    required this.animeIdentifier,
  });

  final String animeTitle;
  final String episodeTitle;
  final int safeIndex;
  final int totalEpisodes;
  final String source;
  final String animeIdentifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          _HoverIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.back,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: AppSpacing.md),

          // Titles
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () =>
                        context.go('/anime/$source/$animeIdentifier'),
                    child: Text(
                      animeTitle,
                      style: AppTextStyles.meta.copyWith(
                        color: AppColors.accent,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  episodeTitle,
                  style: AppTextStyles.titleCard.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Episode counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: AppColors.surfaceVariant, width: 0.8),
            ),
            child: Text(
              '${safeIndex + 1} / $totalEpisodes',
              style: AppTextStyles.meta.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EpisodeNavControls — prev/next + episode title
// ---------------------------------------------------------------------------

class _EpisodeNavControls extends StatelessWidget {
  const _EpisodeNavControls({
    required this.currentIndex,
    required this.totalEpisodes,
    this.onPrev,
    this.onNext,
  });

  final int currentIndex;
  final int totalEpisodes;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HoverIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: l10n.playerPrevEpisode,
          onTap: onPrev,
          size: 32,
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          l10n.playerEpisodeCount((currentIndex + 1).toString(), totalEpisodes.toString()),
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        _HoverIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: l10n.playerNextEpisode,
          onTap: onNext,
          size: 32,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _EpisodeSidebar — lista lateral de episódios (wide layout)
// ---------------------------------------------------------------------------

class _EpisodeSidebar extends StatelessWidget {
  const _EpisodeSidebar({
    required this.episodes,
    required this.currentIndex,
    required this.fallbackCoverUrl,
    required this.onSelect,
  });

  final List<AnimeStreamingEpisodeDto> episodes;
  final int currentIndex;
  final String? fallbackCoverUrl;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          left: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.episodes,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: episodes.length,
              itemBuilder: (ctx, i) => _EpisodeListTile(
                episode: episodes[i],
                index: i,
                isActive: i == currentIndex,
                fallbackCoverUrl: fallbackCoverUrl,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EpisodeListTile — tile individual de episódio
// ---------------------------------------------------------------------------

class _EpisodeListTile extends StatefulWidget {
  const _EpisodeListTile({
    required this.episode,
    required this.index,
    required this.isActive,
    required this.fallbackCoverUrl,
    required this.onTap,
  });

  final AnimeStreamingEpisodeDto episode;
  final int index;
  final bool isActive;
  final String? fallbackCoverUrl;
  final VoidCallback onTap;

  @override
  State<_EpisodeListTile> createState() => _EpisodeListTileState();
}

class _EpisodeListTileState extends State<_EpisodeListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final canEmbed = resolveEmbedUrl(widget.episode.url) != null;
    final thumbUrl = resolveEpisodeThumbnail(
      widget.episode.url,
      fallbackCoverUrl: widget.fallbackCoverUrl,
    );

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
            vertical: AppSpacing.sm + 2,
          ),
          color: widget.isActive
              ? AppColors.accent.withValues(alpha: 0.12)
              : _hovering
                  ? AppColors.surfaceVariant.withValues(alpha: 0.4)
                  : Colors.transparent,
          child: Row(
            children: [
              // Thumbnail (same source logic as Details > Episodes)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: SizedBox(
                  width: 84,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbUrl != null)
                        ProxiedImage(
                          src: thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: AppColors.surface,
                            child: Center(
                              child: Icon(
                                Icons.movie,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        const ColoredBox(
                          color: AppColors.surface,
                          child: Center(
                            child: Icon(
                              Icons.movie,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.2, 1.0],
                            colors: [
                              Color(0x00000000),
                              Color(0x99000000),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        bottom: 3,
                        child: Text(
                          '${widget.index + 1}',
                          style: AppTextStyles.meta.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Playing indicator or play icon
              Icon(
                widget.isActive
                    ? Icons.equalizer_rounded
                    : canEmbed
                        ? Icons.play_circle_outline
                        : Icons.open_in_new,
                size: 18,
                color: widget.isActive
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Title
              Expanded(
                child: Text(
                  widget.episode.title,
                  style: AppTextStyles.meta.copyWith(
                    color: widget.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Active indicator
              if (widget.isActive)
                Container(
                  width: 4,
                  height: 20,
                  margin: const EdgeInsets.only(left: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HoverIconButton — ícone com hover effect
// ---------------------------------------------------------------------------

class _HoverIconButton extends StatefulWidget {
  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovering && enabled
                  ? AppColors.surface.withValues(alpha: 0.8)
                  : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: enabled
                  ? (_hovering
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)
                  : AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Future<void> _openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
