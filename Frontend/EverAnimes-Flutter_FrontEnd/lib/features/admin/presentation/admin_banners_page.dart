import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/dtos/anime_item_dto.dart';
import '../../../core/utils/proxied_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/dtos/home_banner_dto.dart';
import '../../home/data/home_banner_remote_datasource.dart';
import '../../home/presentation/home_banner_providers.dart';
import '../../search/data/search_remote_datasource.dart';
import '../data/dtos/anime_dtos.dart' show AnimeDto;
import '../domain/animes_providers.dart';

/// Página admin para configurar os banners da home.
/// Segue o mesmo estilo das outras telas admin (users, animes).
class AdminBannersPage extends ConsumerStatefulWidget {
  const AdminBannersPage({super.key});

  @override
  ConsumerState<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends ConsumerState<AdminBannersPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncBanners = ref.watch(homeBannersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banners da Home'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: asyncBanners.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 12),
              Text('Erro ao carregar banners: $err'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
                onPressed: () => ref.invalidate(homeBannersProvider),
              ),
            ],
          ),
        ),
        data: (banners) => _BannersContent(banners: banners),
      ),
    );
  }
}

class _BannersContent extends ConsumerWidget {
  const _BannersContent({required this.banners});

  final List<HomeBannerDto> banners;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final primary =
        banners.where((b) => b.slot == 'home-primary').firstOrNull;
    final secondary =
        banners.where((b) => b.slot == 'home-secondary').firstOrNull;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        // Header
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.view_carousel_outlined,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Banners da Home',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure os banners exibidos na página inicial',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Primary banner
        _BannerSlotCard(
          title: 'Banner Principal (Hero)',
          subtitle:
              'Banner grande no topo da home. Slot: home-primary',
          icon: Icons.panorama_wide_angle_select,
          banner: primary,
          slot: 'home-primary',
        ),

        const SizedBox(height: 16),

        // Secondary banner
        _BannerSlotCard(
          title: 'Banner Secundário (Destaque)',
          subtitle:
              'Banner de destaque no meio da home. Slot: home-secondary',
          icon: Icons.featured_video_outlined,
          banner: secondary,
          slot: 'home-secondary',
        ),

        const SizedBox(height: 24),

        // Info card about limitations
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Atualmente a API suporta 2 slots: home-primary e home-secondary. '
                    'Banners adicionais para o carrossel poderão ser adicionados no futuro.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card de um slot de banner ───────────────────────────────────

class _BannerSlotCard extends ConsumerStatefulWidget {
  const _BannerSlotCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.banner,
    required this.slot,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final HomeBannerDto? banner;
  final String slot;

  @override
  ConsumerState<_BannerSlotCard> createState() => _BannerSlotCardState();
}

class _BannerSlotCardState extends ConsumerState<_BannerSlotCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banner = widget.banner;
    final isConfigured = banner != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estado atual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isConfigured
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurado',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (banner.isLocal)
                          Text('Anime local — ID: ${banner.animeId}',
                              style: theme.textTheme.bodySmall),
                        if (banner.isExternal) ...[
                          Text(
                              'Anime externo — ${banner.externalProvider}',
                              style: theme.textTheme.bodySmall),
                          Text('External ID: ${banner.externalId}',
                              style: theme.textTheme.bodySmall),
                        ],
                      ],
                    )
                  : Text(
                      'Não configurado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // Botão de editar
            FilledButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: Text(isConfigured ? 'Alterar' : 'Configurar'),
              onPressed: () => _showEditDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await showDialog<HomeBannerUpdateDto>(
      context: context,
      builder: (ctx) => _BannerEditDialog(
        slot: widget.slot,
        current: widget.banner,
      ),
    );
    if (result == null || !mounted) return;

    // Salvar no backend
    try {
      final datasource = HomeBannerRemoteDatasource(
          ref.read(apiClientProvider));
      await datasource.update(widget.slot, result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        bustBannerCache(ref);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── Dialog visual de seleção de banner ──────────────────────────

class _BannerEditDialog extends ConsumerStatefulWidget {
  const _BannerEditDialog({
    required this.slot,
    this.current,
  });

  final String slot;
  final HomeBannerDto? current;

  @override
  ConsumerState<_BannerEditDialog> createState() => _BannerEditDialogState();
}

class _BannerEditDialogState extends ConsumerState<_BannerEditDialog> {
  late bool _isLocal;
  final _searchController = TextEditingController();

  // Local animes loaded from provider
  List<AnimeDto> _localAnimes = [];
  bool _localLoading = true;

  // External search results
  List<AnimeItemDto> _externalResults = [];
  bool _externalLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _isLocal = c?.isLocal ?? true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (!_isLocal && query.trim().length >= 2) {
      _searchExternal(query.trim());
    }
  }

  Future<void> _searchExternal(String query) async {
    setState(() => _externalLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final datasource = SearchRemoteDatasource(client);
      final result = await datasource.search(query: query, limit: 20);
      if (mounted) {
        setState(() {
          _externalResults = result.items;
          _externalLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _externalLoading = false);
    }
  }

  void _selectLocal(AnimeDto anime) {
    final dto = HomeBannerUpdateDto(animeId: anime.id);
    Navigator.pop(context, dto);
  }

  void _selectExternal(AnimeItemDto anime) {
    final dto = HomeBannerUpdateDto(
      externalId: anime.externalId ?? '${anime.id}',
      externalProvider: anime.source,
    );
    Navigator.pop(context, dto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Load local animes when in local mode
    if (_isLocal) {
      final asyncAnimes = ref.watch(animesListProvider);
      asyncAnimes.whenData((animes) {
        if (_localAnimes.length != animes.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _localAnimes = animes;
                _localLoading = false;
              });
            }
          });
        }
      });
      if (asyncAnimes.isLoading) {
        _localLoading = true;
      }
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selecionar anime — ${widget.slot}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle local/external
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Local'),
                    icon: Icon(Icons.storage),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Externo'),
                    icon: Icon(Icons.cloud),
                  ),
                ],
                selected: {_isLocal},
                onSelectionChanged: (v) => setState(() {
                  _isLocal = v.first;
                  _searchController.clear();
                  _externalResults = [];
                }),
              ),
              const SizedBox(height: 12),

              // Search field (external mode)
              if (!_isLocal)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar anime externo...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _externalLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),

              if (!_isLocal) const SizedBox(height: 12),

              // Grid of results
              Expanded(
                child: _isLocal
                    ? _buildLocalGrid(theme)
                    : _buildExternalGrid(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalGrid(ThemeData theme) {
    if (_localLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localAnimes.isEmpty) {
      return Center(
        child: Text(
          'Nenhum anime local cadastrado.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _localAnimes.length,
      itemBuilder: (ctx, i) {
        final anime = _localAnimes[i];
        return _AnimeGridTile(
          title: anime.title,
          coverUrl: anime.coverUrl,
          subtitle: 'ID: ${anime.id}',
          onTap: () => _selectLocal(anime),
        );
      },
    );
  }

  Widget _buildExternalGrid(ThemeData theme) {
    if (_externalResults.isEmpty && !_externalLoading) {
      return Center(
        child: Text(
          'Digite pelo menos 2 caracteres para buscar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _externalResults.length,
      itemBuilder: (ctx, i) {
        final anime = _externalResults[i];
        return _AnimeGridTile(
          title: anime.title,
          coverUrl: anime.coverUrl,
          subtitle: '${anime.source} — ${anime.externalId ?? anime.id}',
          onTap: () => _selectExternal(anime),
        );
      },
    );
  }
}

/// A grid tile showing an anime cover image, title, and subtitle.
class _AnimeGridTile extends StatefulWidget {
  const _AnimeGridTile({
    required this.title,
    required this.coverUrl,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String? coverUrl;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_AnimeGridTile> createState() => _AnimeGridTileState();
}

class _AnimeGridTileState extends State<_AnimeGridTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: _hovered ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              Expanded(
                child: widget.coverUrl != null
                    ? ProxiedImage(
                        src: widget.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 28),
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.image, size: 28),
                        ),
                      ),
              ),
              // Title + subtitle
              Container(
                padding: const EdgeInsets.all(6),
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
