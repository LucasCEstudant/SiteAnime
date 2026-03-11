import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _SwaggerEndpoint {
  const _SwaggerEndpoint({
    required this.method,
    required this.path,
    required this.tag,
    this.summary,
    this.description,
    this.parameters = const [],
    this.hasBody = false,
    this.bodySchema,
    this.responses = const {},
  });

  final String method; // GET, POST, PUT, DELETE ...
  final String path;
  final String tag;
  final String? summary;
  final String? description;
  final List<_SwaggerParam> parameters;
  final bool hasBody;
  final Map<String, dynamic>? bodySchema;
  final Map<String, String> responses; // statusCode → description
}

class _SwaggerParam {
  const _SwaggerParam({
    required this.name,
    required this.location, // query, path, header
    this.required = false,
    this.type = 'string',
    this.description,
  });

  final String name;
  final String location;
  final bool required;
  final String type;
  final String? description;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider — fetch and parse swagger.json
// ─────────────────────────────────────────────────────────────────────────────

final _swaggerProvider =
    FutureProvider.autoDispose<List<_SwaggerEndpoint>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final res = await client.get<dynamic>('/swagger/v1/swagger.json');

  final json = res.data is String
      ? jsonDecode(res.data as String) as Map<String, dynamic>
      : res.data as Map<String, dynamic>;

  final paths = json['paths'] as Map<String, dynamic>? ?? {};
  final endpoints = <_SwaggerEndpoint>[];

  for (final entry in paths.entries) {
    final pathStr = entry.key;
    final methods = entry.value as Map<String, dynamic>;

    for (final mEntry in methods.entries) {
      final method = mEntry.key.toUpperCase();
      if (method == 'OPTIONS' || method == 'HEAD') continue;

      final op = mEntry.value as Map<String, dynamic>;
      final tags = (op['tags'] as List?)?.cast<String>() ?? ['Other'];
      final tag = tags.first;

      // Parameters
      final rawParams = (op['parameters'] as List?) ?? [];
      final params = rawParams.map((p) {
        final pm = p as Map<String, dynamic>;
        final schema = pm['schema'] as Map<String, dynamic>?;
        return _SwaggerParam(
          name: pm['name'] as String? ?? '',
          location: pm['in'] as String? ?? 'query',
          required: pm['required'] as bool? ?? false,
          type: schema?['type'] as String? ?? 'string',
          description: pm['description'] as String?,
        );
      }).toList();

      // Request body
      final reqBody = op['requestBody'] as Map<String, dynamic>?;
      final hasBody = reqBody != null;
      Map<String, dynamic>? bodySchema;
      if (hasBody) {
        final content = reqBody['content'] as Map<String, dynamic>?;
        final jsonContent =
            content?['application/json'] as Map<String, dynamic>?;
        bodySchema = jsonContent?['schema'] as Map<String, dynamic>?;
      }

      // Responses
      final rawResponses =
          op['responses'] as Map<String, dynamic>? ?? {};
      final responses = <String, String>{};
      for (final rEntry in rawResponses.entries) {
        final desc =
            (rEntry.value as Map<String, dynamic>)['description'] as String? ??
                '';
        responses[rEntry.key] = desc;
      }

      endpoints.add(_SwaggerEndpoint(
        method: method,
        path: pathStr,
        tag: tag,
        summary: op['summary'] as String?,
        description: op['description'] as String?,
        parameters: params,
        hasBody: hasBody,
        bodySchema: bodySchema,
        responses: responses,
      ));
    }
  }

  // Sort by tag, then path
  endpoints.sort((a, b) {
    final t = a.tag.compareTo(b.tag);
    if (t != 0) return t;
    return a.path.compareTo(b.path);
  });

  return endpoints;
});

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

/// In-app API Explorer (mini Swagger UI).
/// Fetches /swagger/v1/swagger.json and displays endpoints grouped by tag.
class ApiTestPage extends ConsumerWidget {
  const ApiTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncEndpoints = ref.watch(_swaggerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        title: Text(l10n.apiTestTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: asyncEndpoints.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.accent, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.apiTestUnexpectedError(err.toString()),
                  style: const TextStyle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent),
                  onPressed: () => ref.invalidate(_swaggerProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.apiTestRepeat),
                ),
              ],
            ),
          ),
        ),
        data: (endpoints) => _EndpointList(endpoints: endpoints),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        tooltip: l10n.apiTestRepeat,
        onPressed: () => ref.invalidate(_swaggerProvider),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Endpoint grouped list
// ─────────────────────────────────────────────────────────────────────────────

class _EndpointList extends StatelessWidget {
  const _EndpointList({required this.endpoints});

  final List<_SwaggerEndpoint> endpoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Group by tag
    final grouped = <String, List<_SwaggerEndpoint>>{};
    for (final ep in endpoints) {
      grouped.putIfAbsent(ep.tag, () => []).add(ep);
    }
    final tags = grouped.keys.toList()..sort();

    if (endpoints.isEmpty) {
      return Center(
        child: Text(l10n.apiExplorerNoEndpoints,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: AppColors.surface,
          child: Text(
            l10n.apiExplorerEndpointCount(endpoints.length),
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: tags.length,
            itemBuilder: (context, i) {
              final tag = tags[i];
              final eps = grouped[tag]!;
              return _TagSection(tag: tag, endpoints: eps);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag section (collapsible)
// ─────────────────────────────────────────────────────────────────────────────

class _TagSection extends StatelessWidget {
  const _TagSection({required this.tag, required this.endpoints});

  final String tag;
  final List<_SwaggerEndpoint> endpoints;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        collapsedBackgroundColor: AppColors.surface,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        title: Row(
          children: [
            Text(tag,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${endpoints.length}',
                  style:
                      const TextStyle(color: AppColors.accent, fontSize: 12)),
            ),
          ],
        ),
        initiallyExpanded: false,
        children:
            endpoints.map((ep) => _EndpointTile(endpoint: ep)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single endpoint tile
// ─────────────────────────────────────────────────────────────────────────────

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint});

  final _SwaggerEndpoint endpoint;

  static Color methodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static Color responseColor(String code) {
    if (code.startsWith('2')) return Colors.green;
    if (code.startsWith('3')) return Colors.blue;
    if (code.startsWith('4')) return Colors.orange;
    if (code.startsWith('5')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mc = methodColor(endpoint.method);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: mc.withAlpha(60)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: mc.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            endpoint.method,
            style: TextStyle(
                color: mc,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
        ),
        title: Text(
          endpoint.path,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontFamily: 'monospace'),
        ),
        subtitle: endpoint.summary != null
            ? Text(endpoint.summary!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12))
            : null,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (endpoint.description != null &&
                    endpoint.description != endpoint.summary) ...[
                  Text(endpoint.description!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                ],

                // Parameters
                if (endpoint.parameters.isNotEmpty) ...[
                  Text(l10n.apiExplorerParams,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  ...endpoint.parameters.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(p.location,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontFamily: 'monospace')),
                            ),
                            const SizedBox(width: 6),
                            Text(p.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontFamily: 'monospace')),
                            const SizedBox(width: 6),
                            Text(p.type,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                            if (p.required) ...[
                              const SizedBox(width: 6),
                              Text(l10n.apiExplorerRequired,
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                ],

                // Responses
                if (endpoint.responses.isNotEmpty) ...[
                  Text(l10n.apiExplorerResponse,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  ...endpoint.responses.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: responseColor(e.key).withAlpha(30),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(e.key,
                                  style: TextStyle(
                                      color: responseColor(e.key),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace')),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  e.value.isNotEmpty ? e.value : '—',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                ],

                // Try-it button
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: mc.withAlpha(40),
                      foregroundColor: mc,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.send, size: 14),
                    label: Text(l10n.apiExplorerTryIt,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _openTryIt(context, endpoint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTryIt(BuildContext context, _SwaggerEndpoint ep) {
    showDialog(
      context: context,
      builder: (_) => _TryItDialog(endpoint: ep),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Try-it Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _TryItDialog extends ConsumerStatefulWidget {
  const _TryItDialog({required this.endpoint});

  final _SwaggerEndpoint endpoint;

  @override
  ConsumerState<_TryItDialog> createState() => _TryItDialogState();
}

class _TryItDialogState extends ConsumerState<_TryItDialog> {
  final Map<String, TextEditingController> _paramControllers = {};
  final _bodyController = TextEditingController();
  String? _responseBody;
  int? _responseStatus;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    for (final p in widget.endpoint.parameters) {
      _paramControllers[p.name] = TextEditingController();
    }
    if (widget.endpoint.hasBody) {
      _bodyController.text = '{}';
    }
  }

  @override
  void dispose() {
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _loading = true;
      _responseBody = null;
      _responseStatus = null;
      _errorMsg = null;
    });

    try {
      final client = ref.read(apiClientProvider);

      // Build path with path params
      var resolvedPath = widget.endpoint.path;
      final queryParams = <String, dynamic>{};

      for (final p in widget.endpoint.parameters) {
        final val = _paramControllers[p.name]?.text ?? '';
        if (val.isEmpty) continue;
        if (p.location == 'path') {
          resolvedPath = resolvedPath.replaceAll('{${p.name}}', val);
        } else if (p.location == 'query') {
          queryParams[p.name] = val;
        }
      }

      Response<dynamic> res;
      final bodyData =
          widget.endpoint.hasBody && _bodyController.text.isNotEmpty
              ? jsonDecode(_bodyController.text)
              : null;

      switch (widget.endpoint.method) {
        case 'POST':
          res = await client.post<dynamic>(resolvedPath,
              data: bodyData, queryParameters: queryParams);
        case 'PUT':
          res = await client.put<dynamic>(resolvedPath,
              data: bodyData, queryParameters: queryParams);
        case 'DELETE':
          res = await client.delete<dynamic>(resolvedPath,
              queryParameters: queryParams);
        default: // GET
          res = await client.get<dynamic>(resolvedPath,
              queryParameters: queryParams);
      }

      final prettyBody = res.data != null
          ? const JsonEncoder.withIndent('  ').convert(res.data)
          : '';

      setState(() {
        _responseStatus = res.statusCode;
        _responseBody = prettyBody;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMsg = e.message;
        _responseStatus = e.statusCode;
      });
    } on FormatException catch (e) {
      setState(() {
        _errorMsg = 'Invalid JSON body: $e';
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ep = widget.endpoint;
    final mc = _EndpointTile.methodColor(ep.method);

    return Dialog(
      backgroundColor: AppColors.bgBase,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mc.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(ep.method,
                        style: TextStyle(
                            color: mc,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'monospace')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ep.path,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontFamily: 'monospace')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceVariant),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parameters
                      if (ep.parameters.isNotEmpty) ...[
                        Text(l10n.apiExplorerParams,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        ...ep.parameters.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextField(
                                controller: _paramControllers[p.name],
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText:
                                      '${p.name} (${p.location})${p.required ? ' *' : ''}',
                                  labelStyle: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                  hintText: p.type,
                                  hintStyle: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.textSecondary
                                            .withAlpha(80)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColors.accent),
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                      ],

                      // Body
                      if (ep.hasBody) ...[
                        Text(l10n.apiExplorerBody,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bodyController,
                          maxLines: 6,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'JSON',
                            hintStyle: const TextStyle(
                                color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      AppColors.textSecondary.withAlpha(80)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Send button
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style:
                              FilledButton.styleFrom(backgroundColor: mc),
                          onPressed: _loading ? null : _send,
                          icon: _loading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 14),
                          label: Text(l10n.apiExplorerSend),
                        ),
                      ),

                      // Response
                      if (_responseBody != null || _errorMsg != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(l10n.apiExplorerResponse,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if (_responseStatus != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _EndpointTile.responseColor(
                                          _responseStatus.toString())
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text('$_responseStatus',
                                    style: TextStyle(
                                        color:
                                            _EndpointTile.responseColor(
                                                _responseStatus
                                                    .toString()),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace')),
                              ),
                            ],
                            const Spacer(),
                            if (_responseBody != null)
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    size: 16,
                                    color: AppColors.textSecondary),
                                tooltip: 'Copy',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _responseBody!));
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          constraints:
                              const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.card),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _errorMsg ?? _responseBody ?? '',
                              style: TextStyle(
                                color: _errorMsg != null
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
