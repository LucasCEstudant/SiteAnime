import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../data/dtos/home_banner_dto.dart';
import '../data/home_banner_remote_datasource.dart';
import '../../details/presentation/details_providers.dart';
import 'home_providers.dart';

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

/// Cache-bust version counter — increment after every banner update
/// so image widgets append `&_cb=<n>` and bypass stale browser cache.
class _CacheBustNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final bannerCacheBustProvider =
    NotifierProvider<_CacheBustNotifier, int>(_CacheBustNotifier.new);

/// Increments the cache-bust counter and invalidates banner data.
void bustBannerCache(WidgetRef ref) {
  ref.read(bannerCacheBustProvider.notifier).bump();
  ref.invalidate(homeBannersProvider);
}

/// Appends `&_cb=<version>` to a cover URL to bypass browser cache.
String? _cacheBustedUrl(String? url, int version) {
  if (url == null || url.isEmpty || version == 0) return url;
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}_cb=$version';
}

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
  HomeBannerDto banner, {
  int cacheBustVersion = 0,
}) async {
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
          coverUrl: _cacheBustedUrl(details.coverUrl, cacheBustVersion),
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
          coverUrl: _cacheBustedUrl(details.coverUrl, cacheBustVersion),
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
  final cbVersion = ref.watch(bannerCacheBustProvider);
  final banners = await ref.watch(homeBannersProvider.future);
  final primary = banners
      .where((b) => b.slot == 'home-primary')
      .firstOrNull;
  if (primary == null) return null;
  return _resolveBanner(ref, primary, cacheBustVersion: cbVersion);
});

/// Provider que resolve todos os banners secundários (para o carrossel).
/// Hoje a API só tem home-secondary, mas o front já suporta N banners.
final resolvedSecondaryBannersProvider =
    FutureProvider<List<ResolvedBanner>>((ref) async {
  final cbVersion = ref.watch(bannerCacheBustProvider);
  final banners = await ref.watch(homeBannersProvider.future);
  // Pega todos que NÃO sejam home-primary (secundários, terciários, etc.)
  final secondaries =
      banners.where((b) => b.slot != 'home-primary').toList();
  final resolved = <ResolvedBanner>[];
  for (final banner in secondaries) {
    final r = await _resolveBanner(ref, banner, cacheBustVersion: cbVersion);
    if (r != null) resolved.add(r);
  }
  return resolved;
});

/// Provider combinado para o HeroBanner.
/// Tenta o banner primário primeiro; só busca animes locais como fallback
/// se o banner estiver ausente/vazio — evitando a chamada desnecessária
/// a GET /api/animes quando o banner está configurado.
final heroAnimeProvider = FutureProvider<AnimeItemDto?>((ref) async {
  final resolved = await ref.watch(resolvedPrimaryBannerProvider.future);
  if (resolved != null && resolved.anime.coverUrl?.isNotEmpty == true) {
    return resolved.anime;
  }
  // Fallback: primeiro anime local com cover.
  final locals = await ref.watch(localAnimesProvider.future);
  return locals.where((a) => a.coverUrl?.isNotEmpty == true).firstOrNull;
});

/// Provider combinado para o FeaturedExpandedSection.
/// Tenta banners secundários primeiro; só busca animes locais como fallback
/// se não houver banners — evitando a chamada desnecessária a GET /api/animes
/// quando banners estão configurados.
final featuredAnimesProvider = FutureProvider<List<AnimeItemDto>>((ref) async {
  final banners = await ref.watch(resolvedSecondaryBannersProvider.future);
  if (banners.isNotEmpty) {
    return banners.map((b) => b.anime).toList();
  }
  // Fallback: últimos animes locais com cover.
  final locals = await ref.watch(localAnimesProvider.future);
  final candidates =
      locals.where((a) => a.coverUrl?.isNotEmpty == true).toList();
  if (candidates.isEmpty) return [];
  return candidates.length > 3
      ? candidates.sublist(candidates.length - 3)
      : [candidates.last];
});
