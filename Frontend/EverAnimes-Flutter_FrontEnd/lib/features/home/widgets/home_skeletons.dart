import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Home Skeletons — Etapa 8
//
// 8-B HeroBannerSkeleton   — placeholder full-bleed do hero
// 8-C PosterCardSkeleton   — placeholder de card de poster
// 8-D MiniCarouselSkeleton — faixa de miniaturas shimmer
// 8-E FeaturedSectionSkeleton — placeholder bloco featured
// 8-F SectionRowSkeleton   — cabecalho + faixa de cards
// 8-G GenresChipsSkeleton  — chips shimmer
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// 8-B  HeroBannerSkeleton
// ---------------------------------------------------------------------------

class HeroBannerSkeleton extends StatelessWidget {
  const HeroBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;

    return Semantics(
      label: AppLocalizations.of(context)!.loadingFeaturedContent,
      child: SizedBox(
      width: double.infinity,
      height: screenH * 0.72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo shimmer cobrindo tudo
          const ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),

          // Gradiente overlay para dar profundidade ao skeleton
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgBase.withValues(alpha: 0.0),
                    AppColors.bgBase.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Bloco de texto shimmer em baixo-esquerda
          Positioned(
            left: AppSpacing.lg,
            right: screenW * 0.4,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerBox(height: 10, width: 90, borderRadius: 4),
                const SizedBox(height: AppSpacing.sm),
                ShimmerBox(
                  height: 38,
                  width: screenW * 0.35,
                  borderRadius: 6,
                ),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerBox(
                  height: 14,
                  width: double.infinity,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                const ShimmerBox(
                  height: 14,
                  width: double.infinity,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                ShimmerBox(height: 14, width: screenW * 0.20, borderRadius: 4),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: const [
                    ShimmerBox(height: 52, width: 52, borderRadius: 26),
                    SizedBox(width: AppSpacing.sm),
                    ShimmerBox(height: 40, width: 140, borderRadius: AppRadius.btn),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),    // Stack
    ),      // SizedBox
    );      // Semantics
  }
}

// ---------------------------------------------------------------------------
// 8-C  PosterCardSkeleton
// ---------------------------------------------------------------------------

class PosterCardSkeleton extends StatelessWidget {
  const PosterCardSkeleton({
    super.key,
    this.width = 120,
    this.height = 180,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerBox(
          width: width,
          height: height,
          borderRadius: AppRadius.card,
        ),
        const SizedBox(height: 6),
        ShimmerBox(height: 12, width: width * 0.75, borderRadius: 3),
        const SizedBox(height: 4),
        ShimmerBox(height: 10, width: width * 0.5, borderRadius: 3),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 8-D  MiniCarouselSkeleton
// ---------------------------------------------------------------------------

class MiniCarouselSkeleton extends StatelessWidget {
  const MiniCarouselSkeleton({super.key, this.itemCount = 10});

  final int itemCount;

  static const _kCardWidth = 80.0;
  static const _kCardHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => ShimmerBox(
          width: _kCardWidth,
          height: _kCardHeight,
          borderRadius: AppRadius.card,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8-E  FeaturedSectionSkeleton
// ---------------------------------------------------------------------------

class FeaturedSectionSkeleton extends StatelessWidget {
  const FeaturedSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem placeholder
            const ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    height: 22,
                    width: screenW * 0.55,
                    borderRadius: 5,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const ShimmerBox(
                    height: 14,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  ShimmerBox(
                    height: 14,
                    width: screenW * 0.60,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: const [
                      ShimmerBox(height: 36, width: 120, borderRadius: AppRadius.btn),
                      SizedBox(width: AppSpacing.sm),
                      ShimmerBox(height: 36, width: 90, borderRadius: AppRadius.btn),
                    ],
                  ),
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
// 8-F  SectionRowSkeleton
// ---------------------------------------------------------------------------

class SectionRowSkeleton extends StatelessWidget {
  const SectionRowSkeleton({
    super.key,
    this.cardCount = 6,
    this.cardWidth = 120.0,
    this.cardHeight = 180.0,
  });

  final int cardCount;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecalho
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: const [
              ShimmerBox(height: 20, width: 160, borderRadius: 4),
              Spacer(),
              ShimmerBox(height: 16, width: 70, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Faixa de cards
        SizedBox(
          height: cardHeight + 36, // card + labels
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: cardCount,
            separatorBuilder: (_, i) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => PosterCardSkeleton(
              width: cardWidth,
              height: cardHeight,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 8-G  GenresChipsSkeleton
// ---------------------------------------------------------------------------

class GenresChipsSkeleton extends StatelessWidget {
  const GenresChipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: List.generate(
          12,
          (i) => ShimmerBox(
            height: 32,
            width: 60.0 + (i % 4) * 16,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }
}
