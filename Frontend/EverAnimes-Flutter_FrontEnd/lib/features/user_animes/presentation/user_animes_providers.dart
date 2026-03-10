import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../../details/data/dtos/anime_details_dto.dart';
import '../data/dtos/user_anime_dtos.dart';
import '../data/user_animes_remote_datasource.dart';
import '../domain/user_animes_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers de infra
// ─────────────────────────────────────────────────────────────────────────────

final userAnimesRemoteDatasourceProvider =
    Provider<UserAnimesRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserAnimesRemoteDatasource(client);
});

final userAnimesRepositoryProvider = Provider<UserAnimesRepository>((ref) {
  final ds = ref.watch(userAnimesRemoteDatasourceProvider);
  return UserAnimesRepository(ds);
});

// ─────────────────────────────────────────────────────────────────────────────
// Add to list
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado da tentativa de adicionar um anime à lista.
enum AddToListResult {
  added,
  alreadyInList,
  error,
}

/// Resultado estendido com mensagem de erro opcional.
class AddToListOutcome {
  const AddToListOutcome(this.result, {this.errorMessage});
  final AddToListResult result;
  final String? errorMessage;
}

/// Cria um [UserAnimeCreateDto] a partir de um [AnimeItemDto].
///
/// Distingue itens locais (source == 'local' ou externalId ausente) de
/// itens externos para enviar o payload correto à API.
UserAnimeCreateDto _createDtoFromItem(AnimeItemDto anime) {
  final isLocal = anime.source.toLowerCase() == 'local' ||
      (anime.externalId == null || anime.externalId!.isEmpty);

  return UserAnimeCreateDto(
    animeId: isLocal ? anime.id : null,
    externalId: isLocal ? null : anime.externalId,
    externalProvider: isLocal ? null : anime.source,
    title: anime.title,
    year: anime.year,
    coverUrl: anime.coverUrl,
    score: anime.score,
  );
}

/// Cria um [UserAnimeCreateDto] a partir de um [AnimeDetailsDto].
///
/// Mesma lógica de distinção local/externo de [_createDtoFromItem].
UserAnimeCreateDto _createDtoFromDetails(AnimeDetailsDto details) {
  final isLocal = details.source.toLowerCase() == 'local' ||
      (details.externalId == null || details.externalId!.isEmpty);

  return UserAnimeCreateDto(
    animeId: isLocal ? details.id : null,
    externalId: isLocal ? null : details.externalId,
    externalProvider: isLocal ? null : details.source,
    title: details.title,
    year: details.year,
    coverUrl: details.coverUrl,
    score: details.score,
  );
}

/// Provider família que adiciona um anime à lista do usuário.
///
/// Retorna [AddToListOutcome] indicando sucesso, conflito (409) ou erro.
/// Uso: `ref.read(addAnimeToListProvider)(animeItem)`.
final addAnimeToListProvider =
    Provider<Future<AddToListOutcome> Function(AnimeItemDto anime)>((ref) {
  final repo = ref.read(userAnimesRepositoryProvider);
  return (AnimeItemDto anime) async {
    try {
      final dto = _createDtoFromItem(anime);

      // Client-side dedup for local animes (backend only checks external).
      if (dto.animeId != null) {
        final exists = await repo.existsByAnimeId(dto.animeId!);
        if (exists) {
          return const AddToListOutcome(AddToListResult.alreadyInList);
        }
      }

      await repo.add(dto);
      // Invalida a lista paginada para refletir a mudança
      ref.invalidate(userAnimesPageProvider);
      return const AddToListOutcome(AddToListResult.added);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const AddToListOutcome(AddToListResult.alreadyInList);
      }
      return AddToListOutcome(AddToListResult.error, errorMessage: e.message);
    }
  };
});

/// Variante para uso na details page (recebe [AnimeDetailsDto]).
final addDetailsAnimeToListProvider =
    Provider<Future<AddToListOutcome> Function(AnimeDetailsDto details)>((ref) {
  final repo = ref.read(userAnimesRepositoryProvider);
  return (AnimeDetailsDto details) async {
    try {
      final dto = _createDtoFromDetails(details);

      // Client-side dedup for local animes.
      if (dto.animeId != null) {
        final exists = await repo.existsByAnimeId(dto.animeId!);
        if (exists) {
          return const AddToListOutcome(AddToListResult.alreadyInList);
        }
      }

      await repo.add(dto);
      ref.invalidate(userAnimesPageProvider);
      return const AddToListOutcome(AddToListResult.added);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const AddToListOutcome(AddToListResult.alreadyInList);
      }
      return AddToListOutcome(AddToListResult.error, errorMessage: e.message);
    }
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// Lista paginada (para ETAPA 4 – My List page)
// ─────────────────────────────────────────────────────────────────────────────

/// Parâmetros de consulta para a listagem de animes do usuário.
typedef UserAnimesQuery = ({
  String? status,
  int? year,
  int page,
  int pageSize,
});

/// Provider família para buscar uma página de animes do usuário.
final userAnimesPageProvider = FutureProvider.autoDispose
    .family<UserAnimePagedResponseDto, UserAnimesQuery>((ref, query) async {
  final repo = ref.read(userAnimesRepositoryProvider);
  return repo.getAll(
    status: query.status,
    year: query.year,
    page: query.page,
    pageSize: query.pageSize,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Delete
// ─────────────────────────────────────────────────────────────────────────────

/// Remove uma entrada da lista do usuário e invalida o cache.
final deleteUserAnimeProvider =
    Provider<Future<bool> Function(int id)>((ref) {
  final repo = ref.read(userAnimesRepositoryProvider);
  return (int id) async {
    try {
      await repo.delete(id);
      ref.invalidate(userAnimesPageProvider);
      return true;
    } on ApiException {
      return false;
    }
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// Update
// ─────────────────────────────────────────────────────────────────────────────

/// Atualiza parcialmente uma entrada da lista do usuário e invalida o cache.
final updateUserAnimeProvider =
    Provider<Future<bool> Function(int id, UserAnimeUpdateDto dto)>((ref) {
  final repo = ref.read(userAnimesRepositoryProvider);
  return (int id, UserAnimeUpdateDto dto) async {
    try {
      await repo.update(id, dto);
      ref.invalidate(userAnimesPageProvider);
      return true;
    } on ApiException {
      return false;
    }
  };
});
