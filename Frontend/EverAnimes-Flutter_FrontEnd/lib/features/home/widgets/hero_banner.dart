import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/upscalable_hero_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_state_provider.dart';
import '../../details/data/dtos/anime_details_dto.dart';
import '../../user_animes/presentation/user_animes_providers.dart'
    show AddToListResult, AddToListOutcome, addAnimeToListProvider, addDetailsAnimeToListProvider;
import '../presentation/home_banner_providers.dart';
import 'home_skeletons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HeroBanner — Etapa 3
//
// Exibe o primeiro anime da temporada com: imagem full-bleed, overlay em
// gradiente, bloco textual no canto inferior-esquerdo e botão Play centralizado.
// ─────────────────────────────────────────────────────────────────────────────

/// Altura do hero em relação à altura da tela.
const double _kHeroHeightFactor = 0.70;

// Deve ser igual a _kHeroHeightFactor — usado em home_page.dart para o overlap.
// ignore: constant_identifier_names
const double kHeroHeightFactor = _kHeroHeightFactor;

/// HeroBanner lê o provider de temporada e seleciona o primeiro item
/// com coverUrl disponível. Enquanto carrega exibe um fundo escuro.
class HeroBanner extends ConsumerWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = screenHeight * _kHeroHeightFactor;

    // heroAnimeProvider: tenta o banner primário e só busca animes locais
    // como fallback se o banner estiver ausente — evita chamada desnecessária
    // a GET /api/animes quando o banner está configurado.
    final asyncAnime = ref.watch(heroAnimeProvider);

    return ClipPath(
      clipper: const _HeroArcClipper(),
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: asyncAnime.when(
          loading: () => const HeroBannerSkeleton(),
          error: (_, __) => const HeroBannerSkeleton(),
          data: (anime) {
            if (anime == null) return const HeroBannerSkeleton();
            return _HeroContent(anime: anime, heroHeight: heroHeight);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo real do hero
// ─────────────────────────────────────────────────────────────────────────────
class _HeroContent extends StatefulWidget {
  const _HeroContent({required this.anime, required this.heroHeight});

  final AnimeItemDto anime;
  final double heroHeight;

  @override
  State<_HeroContent> createState() => _HeroContentState();
}

class _HeroContentState extends State<_HeroContent> {
  bool _playHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 3-A HeroBackgroundImage ──────────────────────────────────────
        _HeroBackgroundImage(coverUrl: widget.anime.coverUrl!),

        // ── 3-B HeroDarkOverlay ──────────────────────────────────────────
        const _HeroDarkOverlay(),

        // ── 3-C HeroInfoPanel ────────────────────────────────────────────
        Positioned(
          bottom: isMobile ? 80 : 100,
          left: isMobile ? AppSpacing.md : 80,
          right: isMobile ? AppSpacing.md : widget.heroHeight * 0.4,
          child: _HeroInfoPanel(
            anime: widget.anime,
            isMobile: isMobile,
            onNavigate: () {
              final idParam =
                  widget.anime.externalId ?? '${widget.anime.id}';
              context.push('/anime/${widget.anime.source}/$idParam');
            },
          ),
        ),

        // ── 3-F HeroPlayButton ───────────────────────────────────────────
        Center(
          child: Semantics(
            label: AppLocalizations.of(context)!.watchAnime(widget.anime.title),
            button: true,
            child: MouseRegion(
            onEnter: (_) => setState(() => _playHovered = true),
            onExit: (_) => setState(() => _playHovered = false),
            child: GestureDetector(
              onTap: () {
                final idParam =
                    widget.anime.externalId ?? '${widget.anime.id}';
                // Abre direto no player imersivo (episódio 1)
                context.push(
                    '/watch/${widget.anime.source}/$idParam?ep=0');
              },
              child: AnimatedScale(
                scale: _playHovered ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _CircularPlayButton(compact: isMobile),
              ),
            ),
          ),
        ),   // Semantics (= Center.child)
      ),     // Center
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-arc  HeroArcClipper — corte semi-circular suave na base do hero
// ─────────────────────────────────────────────────────────────────────────────

/// Recorta a base do hero com um arco côncavo suave (centro mais alto que
/// as extremidades), criando o efeito de "corte circular" estilo Netflix.
class _HeroArcClipper extends CustomClipper<Path> {
  const _HeroArcClipper();

  @override
  Path getClip(Size size) {
    // As bordas laterais ficam ACIMA, o centro desce até a borda total
    // → arco convexo para cima (⌣), igual à referência Netflix.
    const arcDepth = 55.0;
    final path = Path()
      ..lineTo(0, size.height - arcDepth)   // canto esquerdo SOBE
      ..quadraticBezierTo(
        size.width * 0.5,                   // ponto de controle: centro
        size.height,                        // centro DESCE até a borda total
        size.width,
        size.height - arcDepth,             // canto direito SOBE
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-A HeroBackgroundImage
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBackgroundImage extends StatelessWidget {
  const _HeroBackgroundImage({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return UpscalableHeroImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: l10n.homeFeaturedCover,
      errorBuilder: (ctx, err, st) =>
          const ColoredBox(color: AppColors.bgDeep),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-B HeroDarkOverlay
// ─────────────────────────────────────────────────────────────────────────────
class _HeroDarkOverlay extends StatelessWidget {
  const _HeroDarkOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.3, 1.0],
          colors: [
            Color(0x00000000), // transparente no topo
            Color(0xE6000000), // quase opaco na base
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            stops: [0.5, 1.0],
            colors: [
              Color(0x00000000), // transparente à direita
              Color(0x99000000), // ~60 % à esquerda
            ],
          ),
        ),
        child: Container(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-C HeroInfoPanel
// ─────────────────────────────────────────────────────────────────────────────
class _HeroInfoPanel extends StatelessWidget {
  const _HeroInfoPanel({
    required this.anime,
    required this.onNavigate,
    this.isMobile = false,
  });

  final AnimeItemDto anime;
  final VoidCallback onNavigate;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título
        Text(
          anime.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: isMobile
              ? AppTextStyles.titleHero.copyWith(fontSize: 22)
              : AppTextStyles.titleHero,
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── 3-D HeroMetadataRow ─────────────────────────────────────────
        _HeroMetadataRow(anime: anime),
        const SizedBox(height: AppSpacing.md),

        // ── 3-E AddToListButton + Details ───────────────────────────────
        Row(
          children: [
            AddToListButton(anime: anime),
            const SizedBox(width: AppSpacing.sm),
            TextButton.icon(
              onPressed: onNavigate,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              icon: const Icon(Icons.info_outline, size: 16),
              label: Text(
                AppLocalizations.of(context)!.homeDetails,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-D HeroMetadataRow + StarRatingWidget + RatingBadge
// ─────────────────────────────────────────────────────────────────────────────

/// Fila de metadados: estrelas, ano, badge de score, duração placeholder.
class _HeroMetadataRow extends StatelessWidget {
  const _HeroMetadataRow({required this.anime});

  final AnimeItemDto anime;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (anime.score != null)
          StarRatingWidget(score: anime.score!),
        if (anime.year != null)
          Text(
            '${anime.year}',
            style: AppTextStyles.meta,
          ),
        if (anime.score != null)
          RatingBadge(score: anime.score!),
      ],
    );
  }
}

/// Widget reutilizável de estrelas — aceita score de 0 a 10.
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({super.key, required this.score, this.starSize = 16});

  final double score;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final filled = (score / 2).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star : Icons.star_border,
          color: AppColors.star,
          size: starSize,
        );
      }),
    );
  }
}

/// Badge retangular mostrando o score numérico.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.star.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: AppColors.star.withValues(alpha: 0.5)),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: AppTextStyles.meta.copyWith(color: AppColors.star),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-E AddToListButton
// ─────────────────────────────────────────────────────────────────────────────

/// Botão outline reutilizável "Adicionar à lista".
///
/// Fornece [anime] (para uso a partir de listagens) ou [details]
/// (para uso na página de detalhes). Se nenhum dos dois for fornecido,
/// o botão fica desabilitado.
///
/// - Verifica autenticação → redireciona para /login se necessário.
/// - Trata 409 → "Já está na sua lista".
/// - Bloqueia double-clicks com estado interno de loading.
///
/// [compact] = true reduz padding e esconde o label para uso em cards.
class AddToListButton extends ConsumerStatefulWidget {
  const AddToListButton({
    super.key,
    this.anime,
    this.details,
    this.onTap,
    this.onPressed,
    this.compact = false,
  });

  final AnimeItemDto? anime;
  final AnimeDetailsDto? details;

  /// Callback legado — se fornecido, substitui toda a lógica interna.
  final VoidCallback? onTap;

  /// Alias de [onTap] (compatibilidade com chamadores que preferem onPressed).
  final VoidCallback? onPressed;
  final bool compact;

  @override
  ConsumerState<AddToListButton> createState() => _AddToListButtonState();
}

class _AddToListButtonState extends ConsumerState<AddToListButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    // Se há callback legado, executa e retorna.
    final legacy = widget.onPressed ?? widget.onTap;
    if (legacy != null) {
      legacy();
      return;
    }

    // Auth check
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated) {
      if (mounted) context.push('/login');
      return;
    }

    if (_busy) return;
    setState(() => _busy = true);

    try {
      final AddToListOutcome outcome;
      if (widget.details != null) {
        outcome =
            await ref.read(addDetailsAnimeToListProvider)(widget.details!);
      } else if (widget.anime != null) {
        outcome = await ref.read(addAnimeToListProvider)(widget.anime!);
      } else {
        return;
      }

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      switch (outcome.result) {
        case AddToListResult.added:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addedToList)),
          );
        case AddToListResult.alreadyInList:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.alreadyInList)),
          );
        case AddToListResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(outcome.errorMessage ?? l10n.addToListError),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AddToListButtonView(
      onTap: _handleTap,
      compact: widget.compact,
      busy: _busy,
    );
  }
}

class _AddToListButtonView extends StatelessWidget {
  const _AddToListButtonView({
    required this.onTap,
    this.compact = false,
    this.busy = false,
  });

  final VoidCallback onTap;
  final bool compact;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.textSecondary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.btn),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : const Icon(Icons.add, size: 14, color: AppColors.textPrimary),
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.btn),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle_outline, size: 18),
      label: Text(
        AppLocalizations.of(context)!.homeAddToList,
        style: AppTextStyles.btn,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-F CircularPlayButton (reutilizável em Etapas 6 e 7)
// ─────────────────────────────────────────────────────────────────────────────

/// Botão circular Play com texto "ASSISTIR AGORA" abaixo.
class CircularPlayButton extends StatefulWidget {
  const CircularPlayButton({super.key, this.onTap, this.size = 64});

  final VoidCallback? onTap;
  final double size;

  @override
  State<CircularPlayButton> createState() => _CircularPlayButtonState();
}

class _CircularPlayButtonState extends State<CircularPlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: _hovered ? 0.25 : 0.15),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: widget.size * 0.55,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppLocalizations.of(context)!.homeWatchNow,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Versão simples sem hover próprio (usado quando o pai já controla o hover).
class _CircularPlayButton extends StatelessWidget {
  const _CircularPlayButton({this.compact = false});

  final bool compact;
  static const double _kSize = 64;
  static const double _kSizeMobile = 48;

  @override
  Widget build(BuildContext context) {
    final s = compact ? _kSizeMobile : _kSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: s * 0.55,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppLocalizations.of(context)!.homeWatchNow,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
