import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/dtos/home_banner_dto.dart';
import '../../home/data/home_banner_remote_datasource.dart';
import '../../home/presentation/home_banner_providers.dart';

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
        ref.invalidate(homeBannersProvider);
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

// ─── Dialog de edição de banner ──────────────────────────────────

class _BannerEditDialog extends StatefulWidget {
  const _BannerEditDialog({
    required this.slot,
    this.current,
  });

  final String slot;
  final HomeBannerDto? current;

  @override
  State<_BannerEditDialog> createState() => _BannerEditDialogState();
}

class _BannerEditDialogState extends State<_BannerEditDialog> {
  late bool _isLocal;
  final _animeIdController = TextEditingController();
  final _externalIdController = TextEditingController();
  final _externalProviderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _isLocal = c?.isLocal ?? true;
    if (c != null) {
      if (c.isLocal) {
        _animeIdController.text = '${c.animeId}';
      } else if (c.isExternal) {
        _externalIdController.text = c.externalId ?? '';
        _externalProviderController.text = c.externalProvider ?? '';
      }
    }
  }

  @override
  void dispose() {
    _animeIdController.dispose();
    _externalIdController.dispose();
    _externalProviderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Editar ${widget.slot}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo: local ou externo
              Text('Tipo de anime',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
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
                onSelectionChanged: (v) =>
                    setState(() => _isLocal = v.first),
              ),

              const SizedBox(height: 16),

              if (_isLocal) ...[
                TextFormField(
                  controller: _animeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Anime ID (local)',
                    hintText: 'Ex: 1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'ID é obrigatório';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'ID deve ser um número';
                    }
                    return null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _externalIdController,
                  decoration: const InputDecoration(
                    labelText: 'External ID',
                    hintText: 'Ex: 21 (AniList), 1535 (Kitsu)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'External ID é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _externalProviderController.text.isNotEmpty
                      ? _externalProviderController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'AniList', child: Text('AniList')),
                    DropdownMenuItem(
                        value: 'Kitsu', child: Text('Kitsu')),
                    DropdownMenuItem(
                        value: 'Jikan', child: Text('Jikan')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _externalProviderController.text = v;
                    }
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Provider é obrigatório';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final dto = _isLocal
                ? HomeBannerUpdateDto(
                    animeId: int.parse(_animeIdController.text.trim()),
                  )
                : HomeBannerUpdateDto(
                    externalId: _externalIdController.text.trim(),
                    externalProvider:
                        _externalProviderController.text.trim(),
                  );
            Navigator.pop(context, dto);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
