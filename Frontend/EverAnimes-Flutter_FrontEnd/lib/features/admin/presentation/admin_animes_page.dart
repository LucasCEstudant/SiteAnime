import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/cors_image.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/dtos/home_banner_dto.dart';
import '../../home/data/home_banner_remote_datasource.dart';
import '../../home/presentation/home_banner_providers.dart';
import '../data/dtos/anime_dtos.dart';
import '../domain/animes_providers.dart';

/// Página CRUD de animes admin — Etapa 14.
class AdminAnimesPage extends ConsumerWidget {
  const AdminAnimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animesAsync = ref.watch(animesListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminManageAnimes),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: l10n.reload,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(animesListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAnimesNewAnime),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: animesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          fallbackMessage: l10n.adminAnimesLoadError,
          onRetry: () => ref.invalidate(animesListProvider),
        ),
        data: (animes) {
          if (animes.isEmpty) {
            return Center(
              child: Text(l10n.adminAnimesEmpty),
            );
          }
          return _AnimesList(animes: animes);
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => _AnimeFormDialog(
        title: l10n.adminAnimesCreateTitle,
        onSave: (createDto, detailsDto) async {
          final datasource = ref.read(animesDatasourceProvider);
          // 1) POST /api/animes → retorna AnimeDto com id
          final created = await datasource.create(createDto);
          // 2) PUT /api/animes/{id}/details com detalhes locais
          await datasource.updateDetails(created.id, detailsDto);
          ref.invalidate(animesListProvider);
        },
      ),
    );
  }
}

// ─── Animes List ───

class _AnimesList extends ConsumerWidget {
  const _AnimesList({required this.animes});

  final List<AnimeDto> animes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final l10n = AppLocalizations.of(context)!;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: animes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final anime = animes[index];

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: anime.coverUrl != null
                ? CorsImage(
                    src: anime.coverUrl!,
                    width: 44,
                    height: 62,
                    fit: BoxFit.cover,
                  )
                : _CoverPlaceholder(
                    color: colorScheme.surfaceContainerHighest),
          ),
          title: Text(
            anime.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _buildSubtitle(anime, dateFormat),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showEditDialog(context, ref, anime);
              } else if (action == 'delete') {
                _showDeleteDialog(context, ref, anime);
              } else if (action == 'set-primary') {
                _setAsBanner(context, ref, anime, 'home-primary');
              } else if (action == 'set-secondary') {
                _setAsBanner(context, ref, anime, 'home-secondary');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l10n.edit),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'set-primary',
                child: ListTile(
                  leading: const Icon(Icons.panorama_wide_angle_select),
                  title: const Text('Banner Principal'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'set-secondary',
                child: ListTile(
                  leading: const Icon(Icons.featured_video_outlined),
                  title: const Text('Banner Secundário'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSubtitle(AnimeDto anime, DateFormat dateFormat) {
    final parts = <String>[];
    if (anime.year != null) parts.add('${anime.year}');
    if (anime.status != null) parts.add(anime.status!);
    if (anime.score != null) parts.add('★ ${anime.score!.toStringAsFixed(1)}');
    if (anime.episodeCount != null) parts.add('${anime.episodeCount} eps');
    parts.add('Criado ${dateFormat.format(anime.createdAtUtc.toLocal())}');
    return parts.join(' • ');
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AnimeDto anime) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => _AnimeFormDialog(
        title: l10n.adminAnimesEditTitle,
        initialAnime: anime,
        onSave: (createDto, detailsDto) async {
          final datasource = ref.read(animesDatasourceProvider);
          // 1) PUT /api/animes/{id} (dados básicos)
          await datasource.update(
            anime.id,
            AnimeUpdateDto(
              title: createDto.title,
              synopsis: createDto.synopsis,
              year: createDto.year,
              status: createDto.status,
              score: createDto.score,
              coverUrl: createDto.coverUrl,
            ),
          );
          // 2) PUT /api/animes/{id}/details (detalhes locais)
          await datasource.updateDetails(anime.id, detailsDto);
          ref.invalidate(animesListProvider);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, AnimeDto anime) {
    showDialog(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        anime: anime,
        onConfirm: () async {
          final datasource = ref.read(animesDatasourceProvider);
          await datasource.delete(anime.id);
          ref.invalidate(animesListProvider);
        },
      ),
    );
  }

  Future<void> _setAsBanner(
    BuildContext context,
    WidgetRef ref,
    AnimeDto anime,
    String slot,
  ) async {
    try {
      final datasource = HomeBannerRemoteDatasource(
          ref.read(apiClientProvider));
      await datasource.update(
        slot,
        HomeBannerUpdateDto(animeId: anime.id),
      );
      bustBannerCache(ref);
      if (context.mounted) {
        final label = slot == 'home-primary' ? 'Principal' : 'Secundário';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner $label definido: ${anime.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao definir banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── Cover Placeholder ───

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 62,
      color: color,
      child: const Icon(Icons.movie_outlined, size: 24),
    );
  }
}

// ─── Anime Form Dialog (Create / Edit) ───

class _AnimeFormDialog extends StatefulWidget {
  const _AnimeFormDialog({
    required this.title,
    required this.onSave,
    this.initialAnime,
  });

  final String title;
  final Future<void> Function(
    AnimeCreateDto createDto,
    AnimeLocalDetailsUpdateDto detailsDto,
  ) onSave;
  final AnimeDto? initialAnime;

  bool get isEdit => initialAnime != null;

  @override
  State<_AnimeFormDialog> createState() => _AnimeFormDialogState();
}

class _AnimeFormDialogState extends State<_AnimeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ─ Campos básicos ─
  late final TextEditingController _titleController;
  late final TextEditingController _synopsisController;
  late final TextEditingController _yearController;
  late final TextEditingController _statusController;
  late final TextEditingController _scoreController;
  late final TextEditingController _coverUrlController;

  // ─ Campos de detalhes locais ─
  late final TextEditingController _episodeCountController;
  late final TextEditingController _episodeLengthController;

  // Listas dinâmicas
  late List<_ExternalLinkEntry> _externalLinks;
  late List<_StreamingEpisodeEntry> _streamingEpisodes;

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final anime = widget.initialAnime;

    _titleController = TextEditingController(text: anime?.title ?? '');
    _synopsisController = TextEditingController(text: anime?.synopsis ?? '');
    _yearController =
        TextEditingController(text: anime?.year?.toString() ?? '');
    _statusController = TextEditingController(text: anime?.status ?? '');
    _scoreController =
        TextEditingController(text: anime?.score?.toString() ?? '');
    _coverUrlController = TextEditingController(text: anime?.coverUrl ?? '');

    _episodeCountController =
        TextEditingController(text: anime?.episodeCount?.toString() ?? '');
    _episodeLengthController = TextEditingController(
        text: anime?.episodeLengthMinutes?.toString() ?? '');

    _externalLinks = anime?.externalLinks
            .map((e) => _ExternalLinkEntry(site: e.site, url: e.url))
            .toList() ??
        [];

    _streamingEpisodes = anime?.streamingEpisodes
            .map((e) => _StreamingEpisodeEntry(
                title: e.title, url: e.url, site: e.site ?? ''))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _synopsisController.dispose();
    _yearController.dispose();
    _statusController.dispose();
    _scoreController.dispose();
    _coverUrlController.dispose();
    _episodeCountController.dispose();
    _episodeLengthController.dispose();
    for (final link in _externalLinks) {
      link.dispose();
    }
    for (final ep in _streamingEpisodes) {
      ep.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final createDto = AnimeCreateDto(
        title: _titleController.text.trim(),
        synopsis: _synopsisController.text.trim().isNotEmpty
            ? _synopsisController.text.trim()
            : null,
        year: _yearController.text.trim().isNotEmpty
            ? int.parse(_yearController.text.trim())
            : null,
        status: _statusController.text.trim().isNotEmpty
            ? _statusController.text.trim()
            : null,
        score: _scoreController.text.trim().isNotEmpty
            ? double.parse(_scoreController.text.trim())
            : null,
        coverUrl: _coverUrlController.text.trim().isNotEmpty
            ? _coverUrlController.text.trim()
            : null,
      );

      final detailsDto = AnimeLocalDetailsUpdateDto(
        episodeCount: _episodeCountController.text.trim().isNotEmpty
            ? int.parse(_episodeCountController.text.trim())
            : null,
        episodeLengthMinutes: _episodeLengthController.text.trim().isNotEmpty
            ? int.parse(_episodeLengthController.text.trim())
            : null,
        externalLinks: _externalLinks
            .map((e) => ExternalLinkDto(
                  site: e.siteController.text.trim(),
                  url: e.urlController.text.trim(),
                ))
            .toList(),
        streamingEpisodes: _streamingEpisodes
            .map((e) => StreamingEpisodeDto(
                  title: e.titleController.text.trim(),
                  url: e.urlController.text.trim(),
                  site: e.siteController.text.trim().isNotEmpty
                      ? e.siteController.text.trim()
                      : null,
                ))
            .toList(),
      );

      await widget.onSave(createDto, detailsDto);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() {
        if (e.type == ApiExceptionType.rateLimit) {
          _errorMessage = l10n.rateLimitErrorShort;
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 540,
        height: 600,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: colorScheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ═══════════ DADOS BÁSICOS ═══════════
              Text(l10n.adminAnimesBasicData,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 8),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.adminAnimesTitleLabel,
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.adminAnimesTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Sinopse
              TextFormField(
                controller: _synopsisController,
                decoration: InputDecoration(
                  labelText: l10n.adminAnimesSynopsis,
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 4000,
              ),
              const SizedBox(height: 12),

              // Ano + Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: InputDecoration(
                        labelText: l10n.year,
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final year = int.tryParse(value);
                          if (year == null) return l10n.adminAnimesInvalidYear;
                          if (year < 1900) return l10n.adminAnimesMinYear;
                          if (year > DateTime.now().year + 1) {
                            return l10n.adminAnimesMaxYear((DateTime.now().year + 1).toString());
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _statusController,
                      decoration: InputDecoration(
                        labelText: l10n.status,
                        prefixIcon: const Icon(Icons.info_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Score + Cover URL
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _scoreController,
                      decoration: InputDecoration(
                        labelText: l10n.adminAnimesScore,
                        prefixIcon: const Icon(Icons.star_outline),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final score = double.tryParse(value);
                          if (score == null) return l10n.adminAnimesInvalid;
                          if (score < 0 || score > 10) return l10n.adminAnimesScoreRange;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _coverUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.adminAnimesCoverUrl,
                        prefixIcon: const Icon(Icons.image_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.hasAbsolutePath) {
                            return l10n.invalidUrl;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ═══════════ DETALHES LOCAIS ═══════════
              Text(l10n.adminAnimesLocalDetails,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 8),

              // Episódios + Duração
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _episodeCountController,
                      decoration: InputDecoration(
                        labelText: l10n.adminAnimesEpisodeCount,
                        prefixIcon: const Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final n = int.tryParse(value);
                          if (n == null || n < 0 || n > 5000) {
                            return l10n.adminAnimesEpisodeRange;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _episodeLengthController,
                      decoration: InputDecoration(
                        labelText: l10n.adminAnimesDuration,
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final n = int.tryParse(value);
                          if (n == null || n < 1 || n > 300) {
                            return l10n.adminAnimesDurationRange;
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── External Links ───
              _SectionHeader(
                label: l10n.adminAnimesExternalLinks,
                icon: Icons.link,
                onAdd: () => setState(() =>
                    _externalLinks.add(_ExternalLinkEntry())),
              ),
              ..._externalLinks.asMap().entries.map((entry) {
                final i = entry.key;
                final link = entry.value;
                return _ExternalLinkRow(
                  key: ValueKey(link),
                  entry: link,
                  onRemove: () =>
                      setState(() => _externalLinks.removeAt(i)),
                );
              }),

              const SizedBox(height: 20),

              // ─── Streaming Episodes ───
              _SectionHeader(
                label: l10n.adminAnimesStreamingEpisodes,
                icon: Icons.play_circle_outline,
                onAdd: () => setState(() =>
                    _streamingEpisodes.add(_StreamingEpisodeEntry())),
              ),
              ..._streamingEpisodes.asMap().entries.map((entry) {
                final i = entry.key;
                final ep = entry.value;
                return _StreamingEpisodeRow(
                  key: ValueKey(ep),
                  entry: ep,
                  onRemove: () =>
                      setState(() => _streamingEpisodes.removeAt(i)),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(widget.isEdit ? l10n.save : l10n.create),
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }
}

// ─── Section Header with Add button ───

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.onAdd,
  });

  final String label;
  final IconData icon;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          tooltip: l10n.add,
          onPressed: onAdd,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ─── External Link Entry (mutable controllers) ───

class _ExternalLinkEntry {
  _ExternalLinkEntry({String site = '', String url = ''})
      : siteController = TextEditingController(text: site),
        urlController = TextEditingController(text: url);

  final TextEditingController siteController;
  final TextEditingController urlController;

  void dispose() {
    siteController.dispose();
    urlController.dispose();
  }
}

class _ExternalLinkRow extends StatelessWidget {
  const _ExternalLinkRow({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  final _ExternalLinkEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.siteController,
              decoration: InputDecoration(
                labelText: l10n.site,
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.required : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.urlController,
              decoration: InputDecoration(
                labelText: l10n.url,
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasAbsolutePath) return l10n.invalidUrl;
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.red, size: 20),
            tooltip: l10n.remove,
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Streaming Episode Entry (mutable controllers) ───

class _StreamingEpisodeEntry {
  _StreamingEpisodeEntry({
    String title = '',
    String url = '',
    String site = '',
  })  : titleController = TextEditingController(text: title),
        urlController = TextEditingController(text: url),
        siteController = TextEditingController(text: site);

  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController siteController;

  void dispose() {
    titleController.dispose();
    urlController.dispose();
    siteController.dispose();
  }
}

class _StreamingEpisodeRow extends StatelessWidget {
  const _StreamingEpisodeRow({
    super.key,
    required this.entry,
    required this.onRemove,
  });

  final _StreamingEpisodeEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.required : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.urlController,
              decoration: InputDecoration(
                labelText: l10n.url,
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasAbsolutePath) return l10n.invalidUrl;
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.siteController,
              decoration: InputDecoration(
                labelText: l10n.site,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Colors.red, size: 20),
            tooltip: l10n.remove,
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Delete Confirmation Dialog ───

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.anime,
    required this.onConfirm,
  });

  final AnimeDto anime;
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.adminAnimesDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.adminAnimesDeleteConfirm),
          const SizedBox(height: 8),
          Text(
            widget.anime.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.anime.year != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.adminAnimesDeleteYear(widget.anime.year.toString()),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.adminAnimesDeleteWarning,
            style: TextStyle(color: colorScheme.error, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.delete),
          label: Text(l10n.delete),
          onPressed: _loading ? null : _handleDelete,
        ),
      ],
    );
  }
}
