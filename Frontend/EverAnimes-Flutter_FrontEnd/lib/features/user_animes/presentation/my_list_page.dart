import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../l10n/app_localizations.dart';
import '../data/dtos/user_anime_dtos.dart';
import 'user_animes_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MyListPage — ETAPA 4
//
// Netflix-like grid page showing the user's anime list.
// Features: status/year/name/date filters, editor mode with batch ops.
// ─────────────────────────────────────────────────────────────────────────────

/// Status options for the filter dropdown.
/// Values must match the backend's allowed status strings exactly.
const _kStatusOptions = <String?>[
  null, // Todos
  'watching',
  'completed',
  'plan-to-watch',
  'dropped',
];

/// Localizes a backend status string using the current l10n.
String _localizeStatus(String status, AppLocalizations l10n) {
  switch (status) {
    case 'watching':
      return l10n.myListStatusWatching;
    case 'completed':
      return l10n.myListStatusCompleted;
    case 'plan-to-watch':
      return l10n.myListStatusPlanToWatch;
    case 'dropped':
      return l10n.myListStatusDropped;
    default:
      return status;
  }
}

/// Consistent dark-themed input decoration used across dialogs.
InputDecoration _darkInputDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.textSecondary.withAlpha(80)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accent),
      ),
    );

/// Sort options for client-side ordering.
enum _SortMode { nameAsc, nameDesc, yearDesc, yearAsc, dateAddedDesc, dateUpdatedDesc }

class MyListPage extends ConsumerStatefulWidget {
  const MyListPage({super.key});

  @override
  ConsumerState<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends ConsumerState<MyListPage> {
  final _scrollController = ScrollController();
  String? _selectedStatus;
  int _currentPage = 1;
  static const _kPageSize = 20;

  /// Accumulated items across pages.
  final List<UserAnimeDto> _items = [];
  bool _hasMore = true;
  bool _loadingMore = false;

  // ── Filters ──
  _SortMode _sortMode = _SortMode.dateAddedDesc;
  String _nameFilter = '';
  int? _yearFilter;

  // ── Editor mode ──
  bool _editorMode = false;
  final Set<int> _selectedIds = {};

  /// IDs deletados nesta sessão — evita que o cache do provider os re-adicione.
  final Set<int> _deletedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _currentPage++;
    // Force re-fetch by invalidating if needed — the FutureProvider.family
    // will automatically pick up new params.
    setState(() {}); // triggers rebuild with new _currentPage
  }

  void _resetAndReload() {
    setState(() {
      _items.clear();
      _deletedIds.clear();
      _currentPage = 1;
      _hasMore = true;
      _loadingMore = false;
    });
    // Invalidate to force fresh data
    ref.invalidate(userAnimesPageProvider);
  }

  void _onStatusChanged(String? status) {
    _selectedStatus = status;
    _resetAndReload();
  }

  UserAnimesQuery get _query => (
        status: _selectedStatus,
        year: _yearFilter,
        page: _currentPage,
        pageSize: _kPageSize,
      );

  /// Apply client-side sort and name filter.
  List<UserAnimeDto> get _filteredItems {
    var list = _items.toList();

    // Name filter
    if (_nameFilter.isNotEmpty) {
      final lower = _nameFilter.toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(lower)).toList();
    }

    // Sort
    switch (_sortMode) {
      case _SortMode.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
      case _SortMode.nameDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
      case _SortMode.yearDesc:
        list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case _SortMode.yearAsc:
        list.sort((a, b) => (a.year ?? 0).compareTo(b.year ?? 0));
      case _SortMode.dateAddedDesc:
        list.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      case _SortMode.dateUpdatedDesc:
        list.sort((a, b) =>
            (b.updatedAtUtc ?? b.createdAtUtc)
                .compareTo(a.updatedAtUtc ?? a.createdAtUtc));
    }

    return list;
  }

  // ── Editor helpers ──

  void _toggleEditorMode() {
    setState(() {
      _editorMode = !_editorMode;
      if (!_editorMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredItems.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_filteredItems.map((e) => e.id));
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.remove,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${l10n.myListRemoveConfirm}\n\n(${_selectedIds.length} items)',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final deleteFunc = ref.read(deleteUserAnimeProvider);
    final ids = _selectedIds.toList();
    int successCount = 0;
    for (final id in ids) {
      if (await deleteFunc(id)) {
        successCount++;
        if (mounted) {
          setState(() {
            _deletedIds.add(id);
            _items.removeWhere((e) => e.id == id);
          });
        }
      }
    }
    if (!mounted) return;
    _selectedIds.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$successCount ${l10n.myListRemoved}')),
    );
  }

  Future<void> _batchChangeStatus(String newStatus) async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final updateFunc = ref.read(updateUserAnimeProvider);
    final dto = UserAnimeUpdateDto(status: newStatus);
    int successCount = 0;
    for (final id in _selectedIds.toList()) {
      if (await updateFunc(id, dto)) successCount++;
    }
    if (!mounted) return;
    _selectedIds.clear();
    _resetAndReload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.myListItemsUpdated(successCount))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncPage = ref.watch(userAnimesPageProvider(_query));

    // Accumulate items when data loads
    asyncPage.whenData((page) {
      // Filter out items that were deleted during this session.
      final liveItems =
          page.items.where((e) => !_deletedIds.contains(e.id)).toList();

      if (_currentPage == 1) {
        _items
          ..clear()
          ..addAll(liveItems);
      } else if (_loadingMore) {
        final existingIds = _items.map((e) => e.id).toSet();
        final newItems =
            liveItems.where((e) => !existingIds.contains(e.id)).toList();
        _items.addAll(newItems);
      }
      _hasMore = page.hasMore;
      _loadingMore = false;
    });

    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      bottomNavigationBar: _editorMode
          ? _EditorActionBar(
              selectedCount: _selectedIds.length,
              onDelete: _batchDelete,
              onChangeStatus: _batchChangeStatus,
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Top spacing for floating header ─────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),

          // ── Title + filter bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title + Editor toggle
                  Row(
                    children: [
                      Text(
                        l10n.myList,
                        style:
                            AppTextStyles.titleHero.copyWith(fontSize: 28),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: _toggleEditorMode,
                        icon: Icon(
                          _editorMode ? Icons.check_circle : Icons.edit,
                          color: _editorMode
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        tooltip: _editorMode ? l10n.myListExitEditor : l10n.myListEditorMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Row 2: Responsive toolbar (search + filters)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(175),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.surfaceVariant.withAlpha(150),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 760;

                        Widget buildSearchField() {
                          return SizedBox(
                            height: 40,
                            child: TextField(
                              onChanged: (v) => setState(() => _nameFilter = v),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.headerSearchHint,
                                hintStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: AppColors.bgBase,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.btn),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant.withAlpha(120),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.btn),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant.withAlpha(120),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.btn),
                                  borderSide: const BorderSide(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (isMobile) {
                          final minWidth = ((constraints.maxWidth - AppSpacing.sm * 2) / 3)
                              .clamp(120.0, 220.0)
                              .toDouble();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: double.infinity, child: buildSearchField()),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  SizedBox(
                                    width: minWidth > 150 ? 150 : minWidth,
                                    child: _StatusFilterDropdown(
                                      value: _selectedStatus,
                                      onChanged: _onStatusChanged,
                                    ),
                                  ),
                                  SizedBox(
                                    width: minWidth > 120 ? 120 : minWidth,
                                    child: _YearFilterChip(
                                      value: _yearFilter,
                                      onChanged: (y) {
                                        _yearFilter = y;
                                        _resetAndReload();
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: minWidth > 180 ? 180 : minWidth,
                                    child: _SortDropdown(
                                      value: _sortMode,
                                      onChanged: (m) => setState(() => _sortMode = m),
                                    ),
                                  ),
                                ],
                              ),
                              if (_editorMode) ...[
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: _selectAll,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppColors.accent.withAlpha(180),
                                      ),
                                      foregroundColor: AppColors.accent,
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                    icon: Icon(
                                      _selectedIds.length == filtered.length
                                          ? Icons.deselect
                                          : Icons.select_all,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _selectedIds.length == filtered.length
                                          ? l10n.myListDeselectAll
                                          : l10n.myListSelectAll,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: buildSearchField()),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 150,
                              child: _StatusFilterDropdown(
                                value: _selectedStatus,
                                onChanged: _onStatusChanged,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 120,
                              child: _YearFilterChip(
                                value: _yearFilter,
                                onChanged: (y) {
                                  _yearFilter = y;
                                  _resetAndReload();
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 180,
                              child: _SortDropdown(
                                value: _sortMode,
                                onChanged: (m) => setState(() => _sortMode = m),
                              ),
                            ),
                            if (_editorMode) ...[
                              const SizedBox(width: AppSpacing.sm),
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: _selectAll,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.accent.withAlpha(180),
                                    ),
                                    foregroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  icon: Icon(
                                    _selectedIds.length == filtered.length
                                        ? Icons.deselect
                                        : Icons.select_all,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _selectedIds.length == filtered.length
                                        ? l10n.myListDeselectAll
                                        : l10n.myListSelectAll,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          if (_items.isEmpty && asyncPage.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (_items.isEmpty && asyncPage.hasError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.accent, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.unexpectedError,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _resetAndReload,
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_border,
                        color: AppColors.textSecondary, size: 64),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.myListEmpty,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return _MyListCard(
                      key: ValueKey(item.id),
                      item: item,
                      editorMode: _editorMode,
                      selected: _selectedIds.contains(item.id),
                      onDelete: () => _handleDelete(item),
                      onToggleSelect: () => _toggleSelection(item.id),
                      onQuickEdit: () => _showQuickEditDialog(item),
                    );
                  },
                  childCount: filtered.length,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),

            // ── Loading indicator ──────────────────────────────────
            if (_hasMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
              ),

            // ── Bottom padding ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl * 2),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDelete(UserAnimeDto item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.remove, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${l10n.myListRemoveConfirm}\n\n${item.title}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await ref.read(deleteUserAnimeProvider)(item.id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _deletedIds.add(item.id);
        _items.removeWhere((e) => e.id == item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.myListRemoved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unexpectedError)),
      );
    }
  }

  Future<void> _showQuickEditDialog(UserAnimeDto item) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<UserAnimeUpdateDto>(
      context: context,
      builder: (ctx) => _QuickEditDialog(item: item),
    );
    if (result == null || !mounted) return;

    final success = await ref.read(updateUserAnimeProvider)(item.id, result);
    if (!mounted) return;

    if (success) {
      _resetAndReload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.myListUpdated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unexpectedError)),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusFilterDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLabel = value == null ? l10n.all : _localizeStatus(value!, l10n);
    final selectedColor = value == null ? AppColors.textPrimary : _statusBadgeColor(value!);

    return _FilterFieldShell(
      child: _AnchoredPopupField<String?>(
        valueLabel: selectedLabel,
        valueColor: selectedColor,
        valueWeight: value == null ? FontWeight.w500 : FontWeight.w700,
        trailing: const Icon(Icons.filter_list, color: AppColors.textSecondary, size: 18),
        items: _kStatusOptions
            .map(
              (s) => PopupMenuItem<String?>(
                value: s,
                child: s == null
                    ? Text(
                        l10n.all,
                        style: const TextStyle(color: AppColors.textPrimary),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBadgeColor(s).withAlpha(40),
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          _localizeStatus(s, l10n),
                          style: TextStyle(
                            color: _statusBadgeColor(s),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            )
            .toList(),
        onSelected: onChanged,
      ),
    );
  }

}

class _AnchoredPopupField<T> extends StatelessWidget {
  const _AnchoredPopupField({
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    required this.trailing,
    this.valueColor = AppColors.textPrimary,
    this.valueWeight = FontWeight.w500,
  });

  final String valueLabel;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final Widget trailing;
  final Color valueColor;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 280,
        maxHeight: 280,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      itemBuilder: (context) => items,
      onSelected: onSelected,
      child: Row(
        children: [
          Expanded(
            child: Text(
              valueLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: valueWeight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MyListCard
// ─────────────────────────────────────────────────────────────────────────────

class _MyListCard extends StatefulWidget {
  const _MyListCard({
    super.key,
    required this.item,
    required this.onDelete,
    this.editorMode = false,
    this.selected = false,
    this.onToggleSelect,
    this.onQuickEdit,
  });

  final UserAnimeDto item;
  final VoidCallback onDelete;
  final bool editorMode;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onQuickEdit;

  @override
  State<_MyListCard> createState() => _MyListCardState();
}

class _MyListCardState extends State<_MyListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.editorMode
            ? widget.onToggleSelect
            : () {
                // ── Navegação para detalhes ──
                // Itens locais: animeId deve existir e > 0.
                // Itens externos: externalProvider + externalId.
                final isExternal = item.externalProvider != null &&
                    item.externalProvider!.isNotEmpty &&
                    item.externalId != null &&
                    item.externalId!.isNotEmpty;

                if (isExternal) {
                  context.push(
                      '/anime/${item.externalProvider}/${item.externalId}');
                } else if (item.animeId != null && item.animeId! > 0) {
                  context.push('/anime/local/${item.animeId}');
                } else {
                  // Item inválido — sem rota válida para detalhes.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .unexpectedError),
                    ),
                  );
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered
              ? Matrix4.diagonal3Values(1.04, 1.04, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: widget.editorMode
                ? Border.all(
                    color: widget.selected
                        ? AppColors.accent
                        : AppColors.surfaceVariant.withAlpha(120),
                    width: widget.selected ? 2.2 : 1,
                  )
                : null,
            boxShadow: widget.editorMode && widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(120),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Cover image ─────────────────────────────────────
                if (item.coverUrl != null && item.coverUrl!.isNotEmpty)
                  ProxiedImage(
                    src: item.coverUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          color: AppColors.textSecondary, size: 48),
                    ),
                  ),

                // ── Gradient overlay at bottom ──────────────────────
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.5, 1.0],
                        colors: [
                          Color(0x00000000),
                          Color(0xDD000000),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Info at bottom ──────────────────────────────────
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.year != null) ...[
                            Text(
                              '${item.year}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.score != null && item.score! > 0) ...[
                            const Icon(Icons.star,
                                color: AppColors.star, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              item.score!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.star,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.status != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(item.status!).withAlpha(50),
                            borderRadius:
                                BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Text(
                            _localizeStatus(
                                item.status!, AppLocalizations.of(context)!),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(item.status!),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Delete button (on hover) ────────────────────────
                if (_hovered && !widget.editorMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withAlpha(150),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              color: AppColors.accent, size: 16),
                        ),
                      ),
                    ),
                  ),

                // ── Quick edit button (on hover, non-editor) ────────
                if (_hovered && !widget.editorMode && widget.onQuickEdit != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.black.withAlpha(150),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onQuickEdit,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit,
                              color: AppColors.textPrimary, size: 16),
                        ),
                      ),
                    ),
                  ),

                // ── Editor mode selection overlay ───────────────────
                if (widget.editorMode)
                  Positioned.fill(
                    child: Container(
                      color: widget.selected
                          ? Colors.black.withAlpha(35)
                          : Colors.transparent,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.selected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: widget.selected
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                width: 1.4,
                              ),
                            ),
                            child: widget.selected
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: AppColors.textPrimary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'watching':
        return Colors.lightBlueAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'plan-to-watch':
        return Colors.orangeAccent;
      case 'dropped':
        return Colors.redAccent;
      default:
        return AppColors.textSecondary;
    }
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// _YearFilterChip
// ─────────────────────────────────────────────────────────────────────────────

class _YearFilterChip extends StatelessWidget {
  const _YearFilterChip({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (i) => currentYear - i);
    final active = value != null;

    return _FilterFieldShell(
      borderColor: active ? AppColors.accent : null,
      child: Row(
        children: [
          Expanded(
            child: _AnchoredPopupField<int?>(
              valueLabel: value?.toString() ?? l10n.all,
              valueColor: active ? AppColors.accent : AppColors.textPrimary,
              valueWeight: active ? FontWeight.w700 : FontWeight.w500,
              trailing: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textSecondary, size: 18),
              items: [
                PopupMenuItem<int?>(
                  value: null,
                  child: Text(
                    l10n.all,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...years.map(
                  (y) => PopupMenuItem<int?>(
                    value: y,
                    child: Text(
                      '$y',
                      style: TextStyle(
                        color:
                            value == y ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            value == y ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              onSelected: onChanged,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(null),
              child: const Icon(Icons.close, color: AppColors.accent, size: 17),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SortDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final _SortMode value;
  final ValueChanged<_SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _FilterFieldShell(
      child: _AnchoredPopupField<_SortMode>(
        valueLabel: _sortLabel(value, l10n),
        trailing: const Icon(Icons.sort, color: AppColors.textSecondary, size: 18),
        items: _SortMode.values
            .map(
              (m) => PopupMenuItem<_SortMode>(
                value: m,
                child: Text(
                  _sortLabel(m, l10n),
                  style: TextStyle(
                    color: m == value ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: m == value ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        onSelected: onChanged,
      ),
    );
  }

  static String _sortLabel(_SortMode m, AppLocalizations l10n) {
    switch (m) {
      case _SortMode.nameAsc:
        return l10n.myListSortAZ;
      case _SortMode.nameDesc:
        return l10n.myListSortZA;
      case _SortMode.yearDesc:
        return l10n.myListSortYearDesc;
      case _SortMode.yearAsc:
        return l10n.myListSortYearAsc;
      case _SortMode.dateAddedDesc:
        return l10n.myListSortDateAdded;
      case _SortMode.dateUpdatedDesc:
        return l10n.myListSortDateUpdated;
    }
  }
}

class _FilterFieldShell extends StatelessWidget {
  const _FilterFieldShell({
    required this.child,
    this.borderColor,
  });

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(AppRadius.btn),
        border: Border.all(
          color: borderColor ?? AppColors.surfaceVariant.withAlpha(120),
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditorActionBar
// ─────────────────────────────────────────────────────────────────────────────

class _EditorActionBar extends StatelessWidget {
  const _EditorActionBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onChangeStatus,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 640;
    final deleteIconSize = isMobile ? 20.0 : 22.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 18,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFB3262D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.card),
            topRight: Radius.circular(AppRadius.card),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.myListSelectedCount(selectedCount),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PopupMenuButton<String>(
                  tooltip: l10n.myListChangeStatus,
                  enabled: selectedCount > 0,
                  color: AppColors.surface,
                  onSelected: onChangeStatus,
                  position: PopupMenuPosition.under,
                  constraints: const BoxConstraints(maxWidth: 240),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'watching',
                      child: _StatusMenuBadge(
                        label: l10n.myListStatusWatching,
                        color: _statusBadgeColor('watching'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: _StatusMenuBadge(
                        label: l10n.myListStatusCompleted,
                        color: _statusBadgeColor('completed'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'plan-to-watch',
                      child: _StatusMenuBadge(
                        label: l10n.myListStatusPlanToWatch,
                        color: _statusBadgeColor('plan-to-watch'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'dropped',
                      child: _StatusMenuBadge(
                        label: l10n.myListStatusDropped,
                        color: _statusBadgeColor('dropped'),
                      ),
                    ),
                  ],
                  child: SizedBox(
                    height: isMobile ? 40 : 42,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 14,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.btn),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            color: AppColors.accent,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.myListChangeStatus,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: isMobile ? 40 : 42,
                  width: isMobile ? 44 : 48,
                  child: Material(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.btn),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.btn),
                      onTap: selectedCount > 0 ? onDelete : null,
                      child: Center(
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.accent,
                          size: deleteIconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMenuBadge extends StatelessWidget {
  const _StatusMenuBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickEditDialog
// ─────────────────────────────────────────────────────────────────────────────

class _QuickEditDialog extends StatefulWidget {
  const _QuickEditDialog({required this.item});
  final UserAnimeDto item;

  @override
  State<_QuickEditDialog> createState() => _QuickEditDialogState();
}

class _QuickEditDialogState extends State<_QuickEditDialog> {
  late String? _status;
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _episodesCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _scoreCtrl =
        TextEditingController(text: widget.item.score?.toString() ?? '');
    _episodesCtrl = TextEditingController(
        text: widget.item.episodesWatched?.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _episodesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.item.title,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status
            DropdownButtonFormField<String>(
              initialValue: _status,
              dropdownColor: AppColors.surface,
              decoration: _darkInputDecoration(l10n.status),
              style: const TextStyle(color: AppColors.textPrimary),
              items: [
                DropdownMenuItem(value: 'watching', child: Text(l10n.myListStatusWatching)),
                DropdownMenuItem(value: 'completed', child: Text(l10n.myListStatusCompleted)),
                DropdownMenuItem(value: 'plan-to-watch', child: Text(l10n.myListStatusPlanToWatch)),
                DropdownMenuItem(value: 'dropped', child: Text(l10n.myListStatusDropped)),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Score
            TextField(
              controller: _scoreCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _darkInputDecoration(l10n.myListScore),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Episodes watched
            TextField(
              controller: _episodesCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _darkInputDecoration(l10n.myListEpisodesWatched),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _darkInputDecoration(l10n.myListNotes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () {
            final dto = UserAnimeUpdateDto(
              status: _status,
              score: double.tryParse(_scoreCtrl.text),
              episodesWatched: int.tryParse(_episodesCtrl.text),
              notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
            );
            Navigator.of(context).pop(dto);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

Color _statusBadgeColor(String status) {
  switch (status) {
    case 'watching':
      return Colors.lightBlueAccent;
    case 'completed':
      return Colors.greenAccent;
    case 'plan-to-watch':
      return Colors.orangeAccent;
    case 'dropped':
      return Colors.redAccent;
    default:
      return AppColors.textSecondary;
  }
}