import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/data/dtos/paginated_anime_response_dto.dart';
import '../data/search_remote_datasource.dart';
import '../domain/search_repository.dart';

// ─── Infraestrutura ──────────────────────────────────────────────

/// Provider do datasource de busca.
final searchDatasourceProvider = Provider<SearchRemoteDatasource>((ref) {
  return SearchRemoteDatasource(ref.watch(apiClientProvider));
});

/// Provider do repository de busca.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(searchDatasourceProvider));
});

// ─── Estado da busca ─────────────────────────────────────────────

/// Notifier simples que armazena uma String (substitui o antigo StateProvider).
class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Texto atual do campo de busca.
/// Atualizado pelo debounce (Etapa 6B).
final searchQueryProvider =
    NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

/// Gêneros selecionados para filtro (agora suporta múltiplos).
/// Quando não-vazio, a busca por gênero tem prioridade sobre a busca por texto.
final selectedGenresProvider =
    NotifierProvider<_SelectedGenresNotifier, List<String>>(
        _SelectedGenresNotifier.new);

class _SelectedGenresNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggle(String genre) {
    if (state.contains(genre)) {
      state = state.where((g) => g != genre).toList();
    } else {
      state = [...state, genre];
    }
  }

  void set(List<String> genres) => state = genres;

  void clear() => state = [];
}

/// Provider de compatibilidade — retorna o primeiro gênero selecionado ou ''.
/// Usado para manter compatibilidade com código existente.
final selectedGenreProvider = Provider<String>((ref) {
  final genres = ref.watch(selectedGenresProvider);
  return genres.isNotEmpty ? genres.first : '';
});

/// Ano selecionado para filtro.
/// Quando != null, a busca por ano tem prioridade sobre busca por texto
/// (mas menor prioridade que gênero).
final selectedYearProvider =
    NotifierProvider<_SelectedYearNotifier, int?>(
        _SelectedYearNotifier.new);

class _SelectedYearNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int year) => state = year;

  void clear() => state = null;
}

// ─── Estado paginado de resultados ───────────────────────────────

/// Estado imutável que acumula itens de múltiplas páginas.
class PaginatedSearchState {
  const PaginatedSearchState({
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<AnimeItemDto> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => items.isEmpty;

  PaginatedSearchState copyWith({
    List<AnimeItemDto>? items,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) {
    return PaginatedSearchState(
      items: items ?? this.items,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Provider principal de resultados de busca com paginação por cursor.
///
/// Reage ao [searchQueryProvider], [selectedGenresProvider] e [selectedYearProvider].
///
/// Cenários:
/// 1. Se há texto: usa GET /api/animes/search com Q, Year (opcional), Genres (opcional)
/// 2. Se NÃO há texto mas há gêneros: usa GET /api/animes/filters/genre (gêneros separados por vírgula)
/// 3. Se NÃO há texto e NÃO há gêneros mas há ano: usa GET /api/animes/filters/year
///
/// Quando há texto, gêneros e ano são mantidos como filtros adicionais
/// (o endpoint de busca suporta `Q` + `Genres` + `Year` simultaneamente).
/// Quando NÃO há texto, ano e gêneros são mutuamente exclusivos (escolher
/// ano limpa gêneros e vice-versa).
///
/// Expõe [loadMore] para carregar próximas páginas.
final searchResultsProvider = AsyncNotifierProvider<
    PaginatedSearchNotifier, PaginatedSearchState?>(
  PaginatedSearchNotifier.new,
);

class PaginatedSearchNotifier
    extends AsyncNotifier<PaginatedSearchState?> {
  static const _pageLimit = 20;

  @override
  Future<PaginatedSearchState?> build() async {
    final genres = ref.watch(selectedGenresProvider);
    final year = ref.watch(selectedYearProvider);
    final query = ref.watch(searchQueryProvider).trim();

    // Cenário 1: busca textual (opcionalmente com Year e/ou Genres)
    if (query.length >= 2) {
      final response = await ref
          .watch(searchRepositoryProvider)
          .search(
            query: query,
            limit: _pageLimit,
            year: year,
            genres: genres.isNotEmpty ? genres : null,
          );
      return PaginatedSearchState(
        items: response.items,
        nextCursor: response.nextCursor,
      );
    }

    // Cenário 2: sem texto, apenas gêneros → endpoint de filtro por gênero
    if (genres.isNotEmpty) {
      final genreStr = genres.join(',');
      final response = await ref
          .watch(searchRepositoryProvider)
          .fetchByGenre(genre: genreStr, limit: _pageLimit);
      return PaginatedSearchState(
        items: response.items,
        nextCursor: response.nextCursor,
      );
    }

    // Cenário 3: somente ano (sem texto e sem gêneros)
    if (year != null) {
      final response = await ref
          .watch(searchRepositoryProvider)
          .fetchByYear(year: year, limit: _pageLimit);
      return PaginatedSearchState(
        items: response.items,
        nextCursor: response.nextCursor,
      );
    }

    return null;
  }

  /// Carrega a próxima página usando o cursor armazenado.
  /// Não faz nada se já estiver carregando ou se não houver mais páginas.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    // Marca como carregando mais (sem apagar itens existentes)
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final genres = ref.read(selectedGenresProvider);
      final year = ref.read(selectedYearProvider);
      final query = ref.read(searchQueryProvider).trim();
      final repo = ref.read(searchRepositoryProvider);

      PaginatedAnimeResponseDto response;
      if (query.length >= 2) {
        response = await repo.search(
          query: query,
          limit: _pageLimit,
          cursor: current.nextCursor,
          year: year,
          genres: genres.isNotEmpty ? genres : null,
        );
      } else if (genres.isNotEmpty) {
        response = await repo.fetchByGenre(
          genre: genres.join(','),
          limit: _pageLimit,
          cursor: current.nextCursor,
        );
      } else if (year != null) {
        response = await repo.fetchByYear(
          year: year,
          limit: _pageLimit,
          cursor: current.nextCursor,
        );
      } else {
        return;
      }

      state = AsyncData(PaginatedSearchState(
        items: [...current.items, ...response.items],
        nextCursor: response.nextCursor,
      ));
    } catch (e) {
      // Restaura o estado anterior sem o flag de loading
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

// ─── Sugestões (Etapa 6C) ────────────────────────────────────────

/// Texto digitado em tempo real para sugestões (antes do debounce principal).
final suggestionQueryProvider =
    NotifierProvider<_SuggestionStringNotifier, String>(
        _SuggestionStringNotifier.new);

class _SuggestionStringNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Provider de sugestões rápidas (poucos resultados, limit baixo).
/// Dispara quando o texto de sugestão >= 3 chars.
final suggestionsProvider =
    FutureProvider<PaginatedAnimeResponseDto?>((ref) async {
  final query = ref.watch(suggestionQueryProvider).trim();
  if (query.length < 3) return null;

  return ref.watch(searchRepositoryProvider).search(
        query: query,
        limit: 5,
      );
});

