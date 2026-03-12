import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../core/widgets/anime_card_hover.dart';
import '../../../core/widgets/anime_card_skeleton.dart';
import '../../../features/meta/presentation/meta_providers.dart';
import '../../../features/user_animes/presentation/user_animes_providers.dart';
import 'search_providers.dart';
import '../../../widgets/top_header.dart';

/// Página de busca — Etapa 6 (A+B+C) + gêneros no topo.
///
/// - 6A: busca por submit (Enter / ícone).
/// - 6B: debounce de 500ms no campo de texto.
/// - 6C: sugestões em tempo real (overlay dropdown).
/// - Gêneros: chips no topo, clique filtra por gênero via API.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    super.key,
    this.initialQuery = '',
    this.initialGenre = '',
    this.initialYear,
  });

  final String initialQuery;
  final String initialGenre;
  final int? initialYear;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;
  Timer? _suggestionDebounce;

  /// Counter to limit viewport-fill auto-loads (ultrawide fix).
  int _viewportFillLoads = 0;
  /// Max extra batches to auto-load when content doesn't fill the viewport.
  static const _kMaxViewportFillLoads = 3;

  /// Overlay de sugestões.
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Se veio com gênero na URL, seleciona-o.
      final genre = widget.initialGenre.trim();
      if (genre.isNotEmpty) {
        ref.read(selectedGenresProvider.notifier).set([genre]);
        return; // Gênero tem prioridade sobre query e ano
      }

      // Se veio com ano na URL, seleciona-o.
      final year = widget.initialYear;
      if (year != null) {
        ref.read(selectedYearProvider.notifier).set(year);
        return; // Ano tem prioridade sobre query
      }

      // Se veio com query na URL, popula e dispara busca.
      final q = widget.initialQuery.trim();
      if (q.isNotEmpty) {
        _controller.text = q;
        _submitSearch(q);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _suggestionDebounce?.cancel();
    _removeOverlay();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── Scroll-based pagination ─────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger load when within 200px of the bottom
    if (currentScroll >= maxScroll - 200) {
      ref.read(searchResultsProvider.notifier).loadMore();
    }
  }

  /// Ultrawide fix: after a frame, check if the grid content fits entirely
  /// inside the viewport (no scroll available). If so, auto-load more items
  /// so the user doesn't see a half-empty page.
  void _scheduleViewportFillCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      if (_viewportFillLoads >= _kMaxViewportFillLoads) return;

      final pos = _scrollController.position;
      // Content doesn't fill viewport → trigger loadMore
      if (pos.maxScrollExtent <= 0) {
        final paginatedState = ref.read(searchResultsProvider).value;
        if (paginatedState != null &&
            paginatedState.hasMore &&
            !paginatedState.isLoadingMore) {
          _viewportFillLoads++;
          ref.read(searchResultsProvider.notifier).loadMore();
        }
      }
    });
  }

  // ─── Debounce de busca (6B) ──────────────────────────────────

  void _onSearchChanged(String value) {
    // Genres and year are kept — the backend supports Q + Genres + Year
    // simultaneously via GET /api/animes/search.

    // Debounce para sugestões (6C) — 300ms
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(suggestionQueryProvider.notifier).set(value.trim());
      if (value.trim().length >= 3 && _focusNode.hasFocus) {
        _showSuggestionsOverlay();
      } else {
        _removeOverlay();
      }
    });

    // Debounce para busca principal (6B) — 500ms
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _submitSearch(value);
    });
  }

  void _submitSearch(String value) {
    final query = value.trim();
    // Genres and year are preserved — combined search.
    ref.read(searchQueryProvider.notifier).set(query);
    _removeOverlay();
  }

  /// Toggle de gênero para seleção múltipla.
  /// Text + genre can coexist (backend supports combined search).
  void _toggleGenre(String genre) {
    // If there is text, the search provider will combine text + genres.
    // Only clear year when there is no text (filter-only mode switches axis).
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ref.read(selectedYearProvider.notifier).clear();
    }
    ref.read(selectedGenresProvider.notifier).toggle(genre);
    _removeOverlay();
    _focusNode.unfocus();
  }

  /// Regra especial: quando NÃO há texto e o usuário seleciona ano,
  /// os gêneros selecionados devem ser desmarcados.
  void _selectYear(int? year) {
    final query = ref.read(searchQueryProvider).trim();
    // Se não há texto, limpa gêneros ao selecionar ano.
    if (query.isEmpty) {
      _controller.clear();
      ref.read(searchQueryProvider.notifier).set('');
      ref.read(suggestionQueryProvider.notifier).set('');
      ref.read(selectedGenresProvider.notifier).clear();
    }
    if (year != null) {
      ref.read(selectedYearProvider.notifier).set(year);
    } else {
      ref.read(selectedYearProvider.notifier).clear();
    }
    _removeOverlay();
    _focusNode.unfocus();
  }

  // ─── Sugestões overlay (6C) ──────────────────────────────────

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Pequeno delay para permitir tap na sugestão antes de fechar
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _SuggestionsOverlay(
        layerLink: _layerLink,
        onSelect: _onSuggestionSelected,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSuggestionSelected(AnimeItemDto anime) {
    _controller.text = anime.title;
    _submitSearch(anime.title);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedGenres = ref.watch(selectedGenresProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    final hasActiveFilter = selectedGenres.isNotEmpty || selectedYear != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: kTopHeaderHeight),

          // ─── Filtros: Gêneros (chips Wrap) + Ano (dropdown) ─────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GenreChipsBar(
                    selectedGenres: selectedGenres,
                    onGenreToggled: _toggleGenre,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: _YearDropdown(
                    selectedYear: selectedYear,
                    onYearSelected: _selectYear,
                  ),
                ),
              ],
            ),
          ),

          // ─── Campo de busca ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: selectedGenres.isNotEmpty
                      ? l10n.searchFilterByGenre(selectedGenres.join(', '))
                      : selectedYear != null
                          ? l10n.searchFilterByYear('$selectedYear')
                          : l10n.searchHintDefault,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_controller.text.isNotEmpty || hasActiveFilter)
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).set('');
                            ref.read(suggestionQueryProvider.notifier)
                                .set('');
                            ref.read(selectedGenresProvider.notifier)
                                .clear();
                            ref.read(selectedYearProvider.notifier)
                                .clear();
                            _removeOverlay();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // atualiza suffixIcon
                  _onSearchChanged(value);
                },
                onSubmitted: _submitSearch,
              ),
            ),
          ),

          // ─── Resultados ────────────────────────────────────
          Expanded(
            child: _buildResults(context, asyncResults, query, selectedGenres),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AsyncValue<PaginatedSearchState?> asyncResults,
    String query,
    List<String> selectedGenres,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return asyncResults.when(
      loading: () => _buildSkeletonGrid(),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 12),
              Text(
                error is ApiException
                    ? error.message
                    : l10n.searchError,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                onPressed: () => ref.invalidate(searchResultsProvider),
              ),
            ],
          ),
        ),
      ),
      data: (paginatedState) {
        // Reset viewport-fill counter on new search results
        _viewportFillLoads = 0;
        if (paginatedState == null) {
          return _buildEmptyState(theme, isInitial: true);
        }
        if (paginatedState.isEmpty) {
          return _buildEmptyState(theme,
              isInitial: false,
              query: selectedGenres.isNotEmpty
                  ? selectedGenres.join(', ')
                  : query);
        }
        return _buildResultsGrid(paginatedState);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme,
      {required bool isInitial, String? query}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInitial ? Icons.search : Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isInitial
                  ? l10n.searchSelectGenre
                  : l10n.searchNoResults(query ?? ''),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (ctx, i) => const AnimeCardSkeleton(),
    );
  }

  Widget _buildResultsGrid(PaginatedSearchState paginatedState) {
    final items = paginatedState.items;
    // Extra slot for the loading indicator when there are more pages
    final itemCount =
        paginatedState.hasMore ? items.length + 1 : items.length;

    // Ultrawide: schedule a post-frame check to auto-load if grid
    // content doesn't fill the viewport (no scrollbar yet).
    _scheduleViewportFillCheck();

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      addAutomaticKeepAlives: false,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (ctx, index) {
        // Loading indicator at the end
        if (index >= items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final anime = items[index];
        return Stack(
          children: [
            AnimeCardHover(
              anime: anime,
              onTap: () {
                final idParam = anime.externalId ?? '${anime.id}';
                context.push('/anime/${anime.source}/$idParam');
              },
            ),
            // Botão "+" para adicionar à lista do usuário
            Positioned(
              top: 6,
              right: 6,
              child: _AddToListButton(anime: anime),
            ),
          ],
        );
      },
    );
  }
}

// ─── Barra de gêneros (chips) no topo da busca ───────────────────

class _GenreChipsBar extends ConsumerWidget {
  const _GenreChipsBar({
    required this.selectedGenres,
    required this.onGenreToggled,
  });

  final List<String> selectedGenres;
  final ValueChanged<String> onGenreToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGenres = ref.watch(genresProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título da seção
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l10n.searchGenres,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // Chips em Wrap (responsivo)
        asyncGenres.when(
          loading: () => const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.searchGenresError,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          data: (genres) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: genres.map((genre) {
                final isSelected = selectedGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (_) => onGenreToggled(genre),
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.onPrimaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Year dropdown filter ───────────────────────────────────────

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.selectedYear,
    required this.onYearSelected,
  });

  final int? selectedYear;
  final ValueChanged<int?> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    // Gera lista de anos: ano atual até 1990
    final years = List.generate(
      currentYear - 1989,
      (i) => currentYear - i,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ano',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedYear != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
                color: selectedYear != null
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: selectedYear,
                    hint: Text(
                      'Filtrar',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    isDense: true,
                    icon: Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: selectedYear != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Todos',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      ...years.map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              '$y',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                    ],
                    onChanged: onYearSelected,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overlay de sugestões (Etapa 6C) ─────────────────────────────

class _SuggestionsOverlay extends ConsumerWidget {
  const _SuggestionsOverlay({
    required this.layerLink,
    required this.onSelect,
  });

  final LayerLink layerLink;
  final ValueChanged<AnimeItemDto> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSuggestions = ref.watch(suggestionsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      width: 400,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainer,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: asyncSuggestions.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.searchSuggestionsError,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
              data: (response) {
                if (response == null || response.items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: response.items.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final item = response.items[index];
                    return ListTile(
                      dense: true,
                      leading: item.coverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: ProxiedImage(
                                src: item.coverUrl!,
                                width: 36,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.movie_outlined, size: 24),
                              ),
                            )
                          : const Icon(Icons.movie_outlined, size: 24),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.source}${item.year != null ? ' • ${item.year}' : ''}',
                        style: theme.textTheme.labelSmall,
                      ),
                      onTap: () => onSelect(item),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botão "+" para adicionar anime à lista do usuário ───────────

class _AddToListButton extends ConsumerStatefulWidget {
  const _AddToListButton({required this.anime});

  final AnimeItemDto anime;

  @override
  ConsumerState<_AddToListButton> createState() => _AddToListButtonState();
}

class _AddToListButtonState extends ConsumerState<_AddToListButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final addToList = ref.read(addAnimeToListProvider);
      final outcome = await addToList(widget.anime);
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      switch (outcome.result) {
        case AddToListResult.added:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.addedToList),
              duration: const Duration(seconds: 2),
            ),
          );
          break;
        case AddToListResult.alreadyInList:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.alreadyInList),
              duration: const Duration(seconds: 2),
            ),
          );
          break;
        case AddToListResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(outcome.errorMessage ?? l10n.addToListError),
              duration: const Duration(seconds: 3),
            ),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.add,
                  size: 16,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
