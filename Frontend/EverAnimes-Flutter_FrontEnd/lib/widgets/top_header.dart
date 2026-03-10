import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/dtos/anime_item_dto.dart';
import '../core/data/dtos/paginated_anime_response_dto.dart';
import '../core/providers/scroll_providers.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/proxied_image.dart';
import '../features/auth/domain/auth_state_provider.dart';
import '../core/providers/locale_provider.dart';
import '../features/search/presentation/search_providers.dart';
import '../l10n/app_localizations.dart';

/// Altura visual do header — usada pelas páginas como padding top.
/// Igual a [kToolbarHeight] (56 px) para manter consistência com o AppBar do admin.
const double kTopHeaderHeight = kToolbarHeight;

/// Header transparente sobreposto ao conteúdo.
/// Torna-se semi-opaco conforme o scroll via [_TopHeaderController].
class TopHeader extends ConsumerStatefulWidget {
  const TopHeader({super.key, required this.currentPath});

  /// Caminho da rota ativa, fornecido pelo ShellRoute via AppShell.
  final String currentPath;

  @override
  ConsumerState<TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends ConsumerState<TopHeader> {
  /// Progresso de opacidade do fundo: 0 = topo da home, 1 = scrollado / outra pág.
  double _bgOpacity = 0.0;

  /// Localização atual — atualizada via listener do routeInformationProvider.
  /// Necessário porque GoRouterState.of(context) no ShellRoute retorna o
  /// estado do shell (fixo), nunca a rota filha ativa.
  String _currentLocation = '/';

  late GoRouter _router;
  bool _routerInitialized = false;

  /// Offset a partir do qual o fundo fica totalmente opaco (px de scroll).
  static const _kScrollThreshold = 120.0;

  late final ScrollController _scrollCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!mounted) return;
    if (_routerInitialized) {
      _router.routeInformationProvider.removeListener(_onRouteChange);
    }
    _router = router;
    _routerInitialized = true;
    _router.routeInformationProvider.addListener(_onRouteChange);
    _currentLocation = _router.routeInformationProvider.value.uri.path;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ref.read(homeScrollControllerProvider);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (_routerInitialized) {
      _router.routeInformationProvider.removeListener(_onRouteChange);
    }
    _scrollCtrl.removeListener(_onScroll);
    super.dispose();
  }

  void _onRouteChange() {
    if (!mounted) return;
    final newLoc = _router.routeInformationProvider.value.uri.path;
    if (newLoc != _currentLocation) {
      setState(() => _currentLocation = newLoc);
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final newOpacity =
        (_scrollCtrl.offset / _kScrollThreshold).clamp(0.0, 1.0);
    if ((newOpacity - _bgOpacity).abs() > 0.005) {
      setState(() => _bgOpacity = newOpacity);
    }
  }

  void _handleLogoTap() {
    if (widget.currentPath == '/' && _scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa currentPath do ShellRoute (fonte confiável) para isHome.
    // _currentLocation do listener é mantido como fallback para bgOpacity.
    final isHome = widget.currentPath == '/';
    final eff = isHome ? _bgOpacity : 1.0;

    // Interpola: gradiente escuro→transparente (topo) → sólido #202020 (scrollado).
    final topColor = Color.lerp(
      const Color(0xCC202020), // 80% cinza — gradiente inicial
      AppColors.bgBase,        // #202020 sólido ao scrollar
      eff,
    )!;
    final bottomColor = Color.lerp(
      Colors.transparent,
      AppColors.bgBase,
      eff,
    )!;

    final isMobile = AppBreakpoints.isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: kTopHeaderHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.sm : AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isHome) ...[  
            // ── Home: logo + Explorar + Mangás ───────────────────────────
            _BrandLogo(onTap: _handleLogoTap),
            if (!isMobile) ...[
              const SizedBox(width: AppSpacing.lg),
              const _BrowseMenuButton(),
              const SizedBox(width: AppSpacing.xs),
              const _MangasButton(),
            ],
          ] else ...[  
            // ── Outras páginas: botão de voltar ──────────────────────────
            _BackButton(),
          ],

          const Spacer(),

          // ── 2-D SearchField ───────────────────────────────────────────
          _SearchField(compact: isMobile),
          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.md),

          // ── 2-D.1 LanguageSelector ────────────────────────────────────
          _LanguageSelector(compact: isMobile),
          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),

          // ── 2-E NotificationButton ────────────────────────────────────
          const _NotificationButton(),
          SizedBox(width: isMobile ? 0 : AppSpacing.sm),

          // ── 2-E.1 MyListButton (authenticated only) ───────────────────
          if (ref.watch(authStateProvider).isAuthenticated) ...[
            _MyListButton(compact: isMobile),
            SizedBox(width: isMobile ? 0 : AppSpacing.sm),
          ],

          // ── 2-F UserAvatarMenu ────────────────────────────────────────
          _UserAvatarMenu(ref: ref, compact: isMobile),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-B BrandLogo
// ─────────────────────────────────────────────────────────────────────────────
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: const Text(
          'EverAnimes',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BackButton — exibido em páginas não-home no lugar do logo
// ─────────────────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _BackButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      label: Text(
        l10n.back,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-C BrowseMenuButton
// ─────────────────────────────────────────────────────────────────────────────
class _BrowseMenuButton extends StatelessWidget {
  const _BrowseMenuButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => context.push('/genres'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      icon: Text(
        l10n.headerBrowse,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      label: const Icon(
        Icons.arrow_drop_down,
        color: AppColors.textPrimary,
        size: 18,
      ),
    );
  }
}

class _MangasButton extends StatelessWidget {
  const _MangasButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: () => context.push('/mangas'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      child: Text(
        l10n.headerMangas,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-D SearchField  — barra expansível com dropdown de sugestões (Etapa 9.3)
//
// Arquitetura do overlay:
//   • ValueNotifier<List<AnimeItemDto>> _suggestions — fonte de verdade local
//   • ref.listen(suggestionsProvider) → atualiza o notifier
//   • OverlayEntry usa ValueListenableBuilder → reage sem depender de ref
// ─────────────────────────────────────────────────────────────────────────────

// Largura do campo expandido (desktop).
const double _kSearchWidth = 300.0;
// Largura do campo expandido (mobile).
const double _kSearchWidthMobile = 160.0;

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({this.compact = false});

  /// When true, uses a narrower width suitable for mobile.
  final bool compact;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  bool _expanded = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  Timer? _debounce;

  /// ValueNotifier compartilhado com o OverlayEntry (fora da árvore principal).
  final _suggestions = ValueNotifier<List<AnimeItemDto>>([]);

  /// Sinaliza que a API está sendo consultada (mostra skeleton no dropdown).
  final _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    _closeDropdown();
    _suggestions.dispose();
    _loading.dispose();
    super.dispose();
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      // Delay para o tap num item registrar antes de fechar.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _closeDropdown();
      });
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      _loading.value = false;
      _suggestions.value = [];
      ref.read(suggestionQueryProvider.notifier).set('');
      _closeDropdown();
      return;
    }
    // Abre o dropdown imediatamente com skeleton.
    _loading.value = true;
    _suggestions.value = [];
    _ensureOverlay();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(suggestionQueryProvider.notifier).set(value.trim());
    });
  }

  // ── Overlay ────────────────────────────────────────────────────────────────

  void _ensureOverlay() {
    if (_overlay != null) return;
    _overlay = OverlayEntry(
      builder: (_) => _SearchDropdownOverlay(
        layerLink: _layerLink,
        suggestions: _suggestions,
        loading: _loading,
        fieldWidth: _kSearchWidth,
        onSelect: (item) {
          _closeDropdown();
          _ctrl.clear();
          _loading.value = false;
          _suggestions.value = [];
          ref.read(suggestionQueryProvider.notifier).set('');
          setState(() => _expanded = false);
          final id = item.externalId ?? '${item.id}';
          context.push('/anime/${item.source}/$id');
        },
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeDropdown() {
    _overlay?.remove();
    _overlay = null;
  }

  // ── Submit (Enter / lupa) ──────────────────────────────────────────────────

  void _submit(String query) {
    _closeDropdown();
    _debounce?.cancel();
    _loading.value = false;
    _suggestions.value = [];
    ref.read(suggestionQueryProvider.notifier).set('');
    if (query.trim().isEmpty) {
      setState(() => _expanded = false);
      return;
    }
    context.push('/search?q=${Uri.encodeComponent(query.trim())}');
    _ctrl.clear();
    setState(() => _expanded = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Escuta o provider de sugestões e atualiza o ValueNotifier local.
    // Funciona FORA do OverlayEntry porque está na árvore principal.
    ref.listen<AsyncValue<PaginatedAnimeResponseDto?>>(
      suggestionsProvider,
      (prev, next) {
        // Loading terminou — seja com dados ou vazio.
        if (!next.isLoading) _loading.value = false;
        final items = next.asData?.value?.items ?? [];
        _suggestions.value = items;
        // Se chegaram itens e overlay não existe mais, abre.
        if (items.isNotEmpty && _expanded) _ensureOverlay();
        // Se ficou vazio E não está carregando, fecha.
        if (items.isEmpty && !next.isLoading) _closeDropdown();
      },
    );

    final expandedWidth = widget.compact ? _kSearchWidthMobile : _kSearchWidth;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: _expanded ? expandedWidth : 38,
        height: 38,
        curve: Curves.easeOutCubic,
        child: _expanded ? _buildExpandedField() : _buildCollapsedButton(),
      ),
    );
  }

  /// Campo expandido: vidro translúcido + blur
  Widget _buildExpandedField() {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.headerSearchHint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: _submit,
                ),
              ),
              GestureDetector(
                onTap: () => _submit(_ctrl.text),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão colapsado: só ícone
  Widget _buildCollapsedButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _expanded = true);
        // Solicita foco explicitamente após o frame ser construído,
        // garantindo que o TextField já existe na árvore.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: const Icon(Icons.search, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchDropdownOverlay — OverlayEntry reativo via ValueListenableBuilder
// ─────────────────────────────────────────────────────────────────────────────

class _SearchDropdownOverlay extends StatelessWidget {
  const _SearchDropdownOverlay({
    required this.layerLink,
    required this.suggestions,
    required this.loading,
    required this.fieldWidth,
    required this.onSelect,
  });

  final LayerLink layerLink;
  final ValueNotifier<List<AnimeItemDto>> suggestions;
  final ValueNotifier<bool> loading;
  final double fieldWidth;
  final ValueChanged<AnimeItemDto> onSelect;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 44),
        child: Material(
          color: Colors.transparent,
          // Ouve AMBOS os notifiers e reconstrói quando qualquer um muda.
          child: ListenableBuilder(
            listenable: Listenable.merge([suggestions, loading]),
            builder: (ctx, child) {
              final items = suggestions.value;
              final isLoading = loading.value;

              // Nada a mostrar
              if (!isLoading && items.isEmpty) return const SizedBox.shrink();

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: fieldWidth,
                    constraints: const BoxConstraints(maxHeight: 340),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isLoading && items.isEmpty
                        ? const _SearchSkeletonList()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (ctx, i) => Divider(
                              height: 1,
                              color:
                                  Colors.white.withValues(alpha: 0.07),
                              indent: 56,
                              endIndent: 12,
                            ),
                            itemBuilder: (ctx, i) => _SuggestionItem(
                              item: items[i],
                              onTap: onSelect,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchSkeletonList — animação de carregamento (3 linhas pulsando)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchSkeletonList extends StatefulWidget {
  const _SearchSkeletonList();
  @override
  State<_SearchSkeletonList> createState() => _SearchSkeletonListState();
}

class _SearchSkeletonListState extends State<_SearchSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => _SkeletonRow(opacity: _anim.value),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          // Thumbnail box
          Opacity(
            opacity: opacity,
            child: Container(
              width: 32,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: opacity,
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: opacity * 0.75,
                  child: Container(
                    height: 10,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionItem — linha individual no dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionItem extends StatefulWidget {
  const _SuggestionItem({required this.item, required this.onTap});
  final AnimeItemDto item;
  final ValueChanged<AnimeItemDto> onTap;

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 32,
                  height: 46,
                  child: widget.item.coverUrl != null
                      ? ProxiedImage(
                          src: widget.item.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.movie_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: _hovered
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.item.year != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.item.year}',
                        style: AppTextStyles.meta.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-D.1 LanguageSelector
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector({this.compact = false});

  /// When true, shows only the flag emoji without the label text.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    // Resolve the flag for the currently active locale.
    final currentOption = localeOptions.firstWhere(
      (o) => o.locale.languageCode == current.languageCode,
      orElse: () => localeOptions.first,
    );

    return PopupMenuButton<Locale>(
      tooltip: '',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      onSelected: (locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (_) => localeOptions.map((option) {
        final isSelected =
            option.locale.languageCode == current.languageCode;
        return PopupMenuItem<Locale>(
          value: option.locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check, size: 16, color: AppColors.accent),
              ],
            ],
          ),
        );
      }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentOption.flag, style: const TextStyle(fontSize: 16)),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              currentOption.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-E.1 MyListButton
// ─────────────────────────────────────────────────────────────────────────────
class _MyListButton extends StatelessWidget {
  const _MyListButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.bookmark_outline),
      color: AppColors.textPrimary,
      iconSize: 22,
      tooltip: l10n.headerMyList,
      onPressed: () => context.push('/my-list'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-E NotificationButton
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.notifications_none),
      color: AppColors.textPrimary,
      iconSize: 22,
      tooltip: l10n.headerNotifications,
      onPressed: () {
        // Placeholder — funcionalidade futura
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-F UserAvatarMenu
// ─────────────────────────────────────────────────────────────────────────────
class _UserAvatarMenu extends StatelessWidget {
  const _UserAvatarMenu({required this.ref, this.compact = false});

  final WidgetRef ref;

  /// When true, hides the username text and shows only the avatar.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      // Fallback anônimo — botão de login
      return TextButton(
        onPressed: () => context.push('/login'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        child: Text(
          l10n.login,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    final username = (authState.email?.isNotEmpty == true)
        ? authState.email!.split('@').first
        : l10n.headerProfile;
    final initial = username[0].toUpperCase();
    final isAdmin = authState.role.toLowerCase() == 'admin';

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.push('/profile');
          case 'admin':
            context.push('/admin');
          case 'logout':
            ref.read(authStateProvider.notifier).logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            username,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const PopupMenuDivider(),
        _menuItem(Icons.account_circle_outlined, l10n.headerProfile, 'profile'),
        if (isAdmin)
          _menuItem(Icons.admin_panel_settings_outlined, l10n.headerAdmin, 'admin'),
        const PopupMenuDivider(),
        _menuItem(Icons.logout, l10n.logout, 'logout'),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.accent,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              username,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
