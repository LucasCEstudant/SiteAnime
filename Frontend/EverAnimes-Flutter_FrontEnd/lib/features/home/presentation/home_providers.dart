import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/data/dtos/paginated_anime_response_dto.dart';
import '../../admin/data/animes_remote_datasource.dart';
import '../data/anime_remote_datasource.dart';
import '../domain/anime_repository.dart';

/// Provider do datasource de animes.
final animeDatasourceProvider = Provider<AnimeRemoteDatasource>((ref) {
  return AnimeRemoteDatasource(ref.watch(apiClientProvider));
});

/// Provider do repository de animes.
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository(ref.watch(animeDatasourceProvider));
});

/// Provider assíncrono que expõe a primeira página de animes da temporada atual.
final seasonNowProvider = FutureProvider<PaginatedAnimeResponseDto>((ref) {
  return ref.watch(animeRepositoryProvider).getSeasonNow(limit: 20);
});

/// Provider que busca todos os animes do banco local via GET /api/animes.
/// Converte [AnimeDto] → [AnimeItemDto] com source='local'.
/// Temporário: para testes visuais no hero e featured section.
final localAnimesProvider = FutureProvider<List<AnimeItemDto>>((ref) async {
  final datasource = AnimesRemoteDatasource(ref.watch(apiClientProvider));
  final dtos = await datasource.getAll();
  return dtos
      .map((d) => AnimeItemDto(
            source: 'local',
            id: d.id,
            title: d.title,
            year: d.year,
            score: d.score,
            coverUrl: d.coverUrl,
          ))
      .toList();
});
