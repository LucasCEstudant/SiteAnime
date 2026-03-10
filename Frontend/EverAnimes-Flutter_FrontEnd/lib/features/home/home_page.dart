import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/scroll_providers.dart';
import '../../l10n/app_localizations.dart';
import 'presentation/home_banner_providers.dart';
import 'presentation/home_providers.dart';
import 'widgets/featured_section.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_footer.dart';
import 'widgets/home_skeletons.dart';
import 'widgets/mini_carousel.dart';
import 'widgets/section_row.dart';

/// Home — Etapa visual streaming.
/// AppBar removido: o TopHeader do AppShell é sobreposto via Stack.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Sem AppBar — TopHeader do AppShell cobre o topo via Stack.
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(seasonNowProvider);
          ref.invalidate(homeBannersProvider);
        },
        child: ListView(
          controller: ref.watch(homeScrollControllerProvider),
          padding: EdgeInsets.zero,
          children: [
            // Hero + MiniCarousel sobrepostos (mini carousel flutua sobre
            // a parte inferior do hero, replicando layout Netflix)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final screenH = MediaQuery.sizeOf(ctx).height;
                // Deve coincidir com kHeroHeightFactor em hero_banner.dart
                final heroH = screenH * kHeroHeightFactor;
                const overlapAmt = 70.0;
                final isMobile =
                    constraints.maxWidth < 600;
                final carouselFraction = isMobile ? 0.90 : 0.60;
                final carouselH = miniCarouselHeightFor(
                    constraints.maxWidth * carouselFraction);
                final hPad =
                    constraints.maxWidth * (isMobile ? 0.05 : 0.20);
                return SizedBox(
                  height: heroH + carouselH - overlapAmt,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Hero preenche do topo até heroH
                      Positioned(
                        left: 0, right: 0, top: 0,
                        height: heroH,
                        child: const RepaintBoundary(child: HeroBanner()),
                      ),
                      // MiniCarousel sobreposto ao fundo do hero
                      Positioned(
                        left: hPad,
                        right: hPad,
                        top: heroH - overlapAmt,
                        child: const RepaintBoundary(child: MiniCarousel()),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Seção remodelada com SectionRow (Etapa 5)
            const _SeasonSectionRow(),
            const SizedBox(height: 32),
            // Bloco de destaque cinematográfico — Etapa 6
            const RepaintBoundary(child: FeaturedExpandedSection()),
            const SizedBox(height: 48),
            // Footer premium cinematográfico — Etapa 8
            const HomeFooter(),
          ],
        ),
      ),
    );
  }
}

// ─── Seção: Temporada Atual (SectionRow — Etapa 5) ──────────────

class _SeasonSectionRow extends ConsumerWidget {
  const _SeasonSectionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSeason = ref.watch(seasonNowProvider);

    return asyncSeason.when(
      loading: () => const SectionRowSkeleton(),
      error: (err, _) => const SizedBox.shrink(),
      data: (response) => SectionRow(
        title: AppLocalizations.of(context)!.homeCurrentSeason,
        sectionIcon: Icons.local_fire_department,
        items: response.items,
        onSeeAll: () => GoRouter.of(context).push('/search'),
      ),
    );
  }
}


