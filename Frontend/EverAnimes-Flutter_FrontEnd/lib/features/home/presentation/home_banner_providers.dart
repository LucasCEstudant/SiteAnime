import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../data/dtos/home_banner_dto.dart';
import '../data/home_banner_remote_datasource.dart';
import '../../details/presentation/details_providers.dart';

// ─── Infraestrutura ──────────────────────────────────────────────

/// Provider do datasource de banners.
final homeBannerDatasourceProvider =
    Provider<HomeBannerRemoteDatasource>((ref) {
  return HomeBannerRemoteDatasource(ref.watch(apiClientProvider));
});

// ─── Dados de banners ────────────────────────────────────────────

/// Provider que busca a lista de banners configurados na API.
final homeBannersProvider = FutureProvider<List<HomeBannerDto>>((ref) {
  return ref.watch(homeBannerDatasourceProvider).getAll();
});

/// Tipo que carrega o banner + anime resolvido para a home.
class ResolvedBanner {
  const ResolvedBanner({
    required this.banner,
    required this.anime,
  });

  final HomeBannerDto banner;
  final AnimeItemDto anime;
}

/// Resolve um [HomeBannerDto] para um [AnimeItemDto] com detalhes.
///
/// Para anime local: busca via details com source='local', id=animeId.
/// Para externo: busca via details com source=externalProvider, externalId.
/// Retorna null se não conseguir resolver.
Future<ResolvedBanner?> _resolveBanner(
  Ref ref,
  HomeBannerDto banner,
) async {
  try {
    if (banner.isLocal && banner.animeId != null) {
      final details = await ref.watch(
        animeDetailsProvider((
          source: 'local',
          id: banner.animeId,
          externalId: null,
        )).future,
      );
      return ResolvedBanner(
        banner: banner,
        anime: AnimeItemDto(
          source: details.source,
          id: details.id,
          externalId: details.externalId,
          title: details.title,
          year: details.year,
          score: details.score,
          coverUrl: details.coverUrl,
          genres: details.genres,
        ),
      );
    } else if (banner.isExternal) {
      final details = await ref.watch(
        animeDetailsProvider((
          source: banner.externalProvider!,
          id: null,
          externalId: banner.externalId,
        )).future,
      );
      return ResolvedBanner(
        banner: banner,
        anime: AnimeItemDto(
          source: details.source,
          id: details.id,
          externalId: details.externalId,
          title: details.title,
          year: details.year,
          score: details.score,
          coverUrl: details.coverUrl,
          genres: details.genres,
        ),
      );
    }
  } catch (_) {
    // Falha silenciosa — fallback será aplicado pelo consumidor.
  }
  return null;
}

/// Provider que resolve o banner primário (home-primary).
final resolvedPrimaryBannerProvider =
    FutureProvider<ResolvedBanner?>((ref) async {
  final banners = await ref.watch(homeBannersProvider.future);
  final primary = banners
      .where((b) => b.slot == 'home-primary')
      .firstOrNull;
  if (primary == null) return null;
  return _resolveBanner(ref, primary);
});

/// Provider que resolve o banner secundário (home-secondary).
final resolvedSecondaryBannerProvider =
    FutureProvider<ResolvedBanner?>((ref) async {
  final banners = await ref.watch(homeBannersProvider.future);
  final secondary = banners
      .where((b) => b.slot == 'home-secondary')
      .firstOrNull;
  if (secondary == null) return null;
  return _resolveBanner(ref, secondary);
});

/// Provider que resolve todos os banners secundários (para o carrossel).
/// Hoje a API só tem home-secondary, mas o front já suporta N banners.
final resolvedSecondaryBannersProvider =
    FutureProvider<List<ResolvedBanner>>((ref) async {
  final banners = await ref.watch(homeBannersProvider.future);
  // Pega todos que NÃO sejam home-primary (secundários, terciários, etc.)
  final secondaries =
      banners.where((b) => b.slot != 'home-primary').toList();
  final resolved = <ResolvedBanner>[];
  for (final banner in secondaries) {
    final r = await _resolveBanner(ref, banner);
    if (r != null) resolved.add(r);
  }
  return resolved;
});
