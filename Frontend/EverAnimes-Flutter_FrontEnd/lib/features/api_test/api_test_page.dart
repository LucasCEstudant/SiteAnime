import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/auth/data/token_storage.dart';
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
    this.bodyExample,
    this.responses = const {},
    this.produces = const [],
    this.responseHasBinaryFormat = false,
  });

  final String method; // GET, POST, PUT, DELETE ...
  final String path;
  final String tag;
  final String? summary;
  final String? description;
  final List<_SwaggerParam> parameters;
  final bool hasBody;
  final Map<String, dynamic>? bodySchema;        // raw resolved schema
  final Map<String, dynamic>? bodyExample;       // pre-built example object
  final Map<String, String> responses;           // statusCode → description
  final List<String> produces;                   // response content-types (2xx)
  final bool responseHasBinaryFormat;            // schema has format:binary

  /// Whether the 2xx response is expected to be binary (image/* etc.).
  bool get isBinaryResponse =>
      produces.any((ct) =>
          ct.startsWith('image/') || ct == 'application/octet-stream') ||
      responseHasBinaryFormat;
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

// ─────────────────────────────────────────────────────────────────────────────
// Schema helpers — $ref resolution + example generation
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves a `$ref` like `#/components/schemas/Foo` against [components].
Map<String, dynamic> _resolveRef(
    String ref, Map<String, dynamic> components) {
  if (!ref.startsWith('#/components/schemas/')) return {};
  final name = ref.replaceFirst('#/components/schemas/', '');
  return (components[name] as Map<String, dynamic>?) ?? {};
}

/// Returns the resolved schema (follows $ref one level).
Map<String, dynamic> _resolveSchema(
    Map<String, dynamic> schema, Map<String, dynamic> components) {
  if (schema.containsKey(r'$ref')) {
    final ref = schema[r'$ref'] as String;
    return _resolveRef(ref, components);
  }
  return schema;
}

/// Builds an example value for a single swagger [rawSchema] node.
dynamic _buildExampleValue(
    Map<String, dynamic> rawSchema, Map<String, dynamic> components,
    [int depth = 0]) {
  if (depth > 6) return null;
  final schema = _resolveSchema(rawSchema, components);

  if (schema.containsKey('example')) return schema['example'];

  final type = schema['type'] as String?;
  final format = schema['format'] as String?;

  for (final key in ['allOf', 'anyOf', 'oneOf']) {
    final list = schema[key] as List?;
    if (list != null && list.isNotEmpty) {
      return _buildExampleValue(
          list.first as Map<String, dynamic>, components, depth + 1);
    }
  }

  switch (type) {
    case 'object':
      final props = schema['properties'] as Map<String, dynamic>?;
      if (props == null) return {};
      return {
        for (final e in props.entries)
          e.key: _buildExampleValue(
              e.value as Map<String, dynamic>, components, depth + 1)
      };
    case 'array':
      final items = schema['items'] as Map<String, dynamic>?;
      if (items == null) return [];
      return [_buildExampleValue(items, components, depth + 1)];
    case 'integer':
      return 0;
    case 'number':
      return 0.0;
    case 'boolean':
      return true;
    case 'string':
      if (format == 'date-time') return '2024-01-01T00:00:00Z';
      if (format == 'date') return '2024-01-01';
      if (format == 'uuid') return '00000000-0000-0000-0000-000000000000';
      if (format == 'uri' || format == 'url') return 'https://example.com';
      if (format == 'email') return 'user@example.com';
      return 'string';
    default:
      final props = schema['properties'] as Map<String, dynamic>?;
      if (props != null) {
        return {
          for (final e in props.entries)
            e.key: _buildExampleValue(
                e.value as Map<String, dynamic>, components, depth + 1)
        };
      }
      return null;
  }
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

  // components.schemas for $ref resolution
  final components =
      ((json['components'] as Map<String, dynamic>?)?['schemas']
          as Map<String, dynamic>?) ??
          {};

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

      // Request body — resolve $ref, build example
      final reqBody = op['requestBody'] as Map<String, dynamic>?;
      final hasBody = reqBody != null;
      Map<String, dynamic>? bodySchema;
      Map<String, dynamic>? bodyExample;
      if (hasBody) {
        final content = reqBody['content'] as Map<String, dynamic>?;
        final jsonContent =
            content?['application/json'] as Map<String, dynamic>?;
        final rawSchema = jsonContent?['schema'] as Map<String, dynamic>?;
        if (rawSchema != null) {
          bodySchema = _resolveSchema(rawSchema, components);
          final exVal = _buildExampleValue(rawSchema, components);
          if (exVal is Map<String, dynamic>) bodyExample = exVal;
        }
      }

      // Responses — description + collect produces content-types for 2xx
      final rawResponses =
          op['responses'] as Map<String, dynamic>? ?? {};
      final responses = <String, String>{};
      final produces = <String>[];
      var hasBinaryFormat = false;
      for (final rEntry in rawResponses.entries) {
        final rv = rEntry.value as Map<String, dynamic>;
        responses[rEntry.key] = rv['description'] as String? ?? '';
        if (rEntry.key.startsWith('2')) {
          final ct = rv['content'] as Map<String, dynamic>?;
          if (ct != null) {
            produces.addAll(ct.keys);
            // Check if any response schema declares format: "binary"
            for (final mediaEntry in ct.values) {
              if (mediaEntry is Map<String, dynamic>) {
                final schema = mediaEntry['schema'] as Map<String, dynamic>?;
                if (schema != null && schema['format'] == 'binary') {
                  hasBinaryFormat = true;
                }
              }
            }
          }
        }
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
        bodyExample: bodyExample,
        responses: responses,
        produces: produces,
        responseHasBinaryFormat: hasBinaryFormat,
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
  Uint8List? _binaryBody;
  String? _binaryContentType;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    for (final p in widget.endpoint.parameters) {
      _paramControllers[p.name] = TextEditingController();
    }
    if (widget.endpoint.hasBody) {
      final ex = widget.endpoint.bodyExample;
      _bodyController.text = ex != null
          ? const JsonEncoder.withIndent('  ').convert(ex)
          : '{}';
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

  Uint8List? _extractBinaryBytes(dynamic data) {
    if (data == null) return null;

    if (data is Uint8List) return data;

    if (data is List<int>) return Uint8List.fromList(data);

    if (data is String) {
      final raw = data.trim();
      if (raw.isEmpty) return null;

      // 1) Try data-URI prefix (e.g. "data:image/png;base64,...")
      var base64Payload = raw;
      final dataUriIdx = raw.indexOf('base64,');
      if (dataUriIdx >= 0) {
        base64Payload = raw.substring(dataUriIdx + 'base64,'.length);
      }

      try {
        return base64Decode(base64Payload);
      } catch (_) {
        // not valid base64 – fall through
      }

      // 2) Raw binary string (Latin-1 / codeUnits) — Dio on web sometimes
      //    decodes binary payloads as String instead of Uint8List.
      try {
        final bytes = Uint8List.fromList(raw.codeUnits);
        // Quick sanity: check for common image headers
        if (bytes.length > 4) {
          final isPng = bytes[0] == 0x89 && bytes[1] == 0x50;
          final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
          final isGif = bytes[0] == 0x47 && bytes[1] == 0x49;
          final isWebp = bytes.length > 11 &&
              bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42;
          if (isPng || isJpeg || isGif || isWebp) return bytes;
        }
        // Even without recognized header, return the bytes —
        // the caller can try rendering them.
        if (bytes.length > 16) return bytes;
      } catch (_) {
        // codeUnits conversion failed
      }

      return null;
    }

    if (data is Map) {
      for (final key in const ['data', 'image', 'bytes', 'base64']) {
        if (!data.containsKey(key)) continue;
        final nested = data[key];
        final parsed = _extractBinaryBytes(nested);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  Future<void> _send() async {
    setState(() {
      _loading = true;
      _responseBody = null;
      _responseStatus = null;
      _binaryBody = null;
      _errorMsg = null;
    });

    try {
      final client = ref.read(apiClientProvider);

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

      Object? bodyData;
      if (widget.endpoint.hasBody && _bodyController.text.trim().isNotEmpty) {
        bodyData = jsonDecode(_bodyController.text);
      }

      // Use ResponseType.bytes when the endpoint declares an image response.
      // On web, Dio's per-request Options(responseType: bytes) may not
      // correctly set xhr.responseType='arraybuffer', causing binary data
      // to be UTF-8-decoded as a String and corrupting high bytes.
      // Fix: create a dedicated Dio instance with ResponseType.bytes baked
      // into BaseOptions so the web adapter sees it during XHR setup.
      final useBinary = widget.endpoint.isBinaryResponse;

      Response<dynamic> res;
      if (useBinary) {
        // Build a fresh Dio with ResponseType.bytes in BaseOptions.
        final binaryDio = Dio(BaseOptions(
          baseUrl: kApiBaseUrl,
          responseType: ResponseType.bytes,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 480),
          headers: {'Accept': '*/*'},
        ));
        // Attach auth token manually.
        final tokenStorage = ref.read(tokenStorageProvider);
        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null) {
          binaryDio.options.headers['Authorization'] = 'Bearer $accessToken';
        }

        switch (widget.endpoint.method) {
          case 'POST':
            res = await binaryDio.post<dynamic>(resolvedPath,
                data: bodyData, queryParameters: queryParams);
          case 'PUT':
            res = await binaryDio.put<dynamic>(resolvedPath,
                data: bodyData, queryParameters: queryParams);
          case 'DELETE':
            res = await binaryDio.delete<dynamic>(resolvedPath,
                queryParameters: queryParams);
          default:
            res = await binaryDio.get<dynamic>(resolvedPath,
                queryParameters: queryParams);
        }
      } else {
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
          default:
            res = await client.get<dynamic>(resolvedPath,
                queryParameters: queryParams);
        }
      }

      final contentType = res.headers.value('content-type') ?? '';
      final isBinary = useBinary ||
          contentType.startsWith('image/') ||
          contentType == 'application/octet-stream' ||
          res.data is Uint8List ||
          res.data is List<int>;

      if (isBinary) {
        final bytes = _extractBinaryBytes(res.data);

        if (bytes != null) {
          setState(() {
            _responseStatus = res.statusCode;
            _binaryBody = bytes;
            _binaryContentType =
                contentType.isNotEmpty ? contentType : 'image/*';
            _responseBody = null;
            _errorMsg = null;
          });
        } else {
          // Show debug info so we can diagnose the format
          final preview = res.data is String
              ? (res.data as String).substring(
                  0,
                  (res.data as String).length > 120
                      ? 120
                      : (res.data as String).length)
              : res.data?.toString().substring(
                      0,
                      (res.data?.toString().length ?? 0) > 120
                          ? 120
                          : (res.data?.toString().length ?? 0)) ??
                  '';
          setState(() {
            _responseStatus = res.statusCode;
            _errorMsg =
                'Expected binary response but received unsupported data format.\n'
                'Content-Type: $contentType\n'
                'Runtime type: ${res.data.runtimeType}\n'
                'Data length: ${res.data is String ? (res.data as String).length : "?"}\n'
                'Preview: $preview';
            _binaryBody = null;
            _responseBody = null;
          });
        }
      } else {
        String prettyBody;
        try {
          prettyBody = res.data != null
              ? const JsonEncoder.withIndent('  ').convert(res.data)
              : '';
        } catch (_) {
          prettyBody = res.data?.toString() ?? '';
        }
        setState(() {
          _responseStatus = res.statusCode;
          _responseBody = prettyBody;
          _binaryBody = null;
          _binaryContentType = null;
          _errorMsg = null;
        });
      }
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
    final hasResponse =
        _responseBody != null || _errorMsg != null || _binaryBody != null;

    return Dialog(
      backgroundColor: AppColors.bgBase,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
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
              if (ep.summary != null) ...[
                const SizedBox(height: 4),
                Text(ep.summary!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
              // produces badge
              if (ep.produces.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: ep.produces
                      .map((ct) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(ct,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontFamily: 'monospace')),
                          ))
                      .toList(),
                ),
              ],
              const Divider(color: AppColors.surfaceVariant),

              // ── Scrollable content ───────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parameters
                      if (ep.parameters.isNotEmpty) ...[
                        _sectionLabel(l10n.apiExplorerParams),
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
                                  hintText: p.description ?? p.type,
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
                        const SizedBox(height: 4),
                      ],

                      // Request body
                      if (ep.hasBody) ...[
                        Row(
                          children: [
                            _sectionLabel(l10n.apiExplorerBody),
                            const Spacer(),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppColors.textSecondary),
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset',
                                  style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                final ex = widget.endpoint.bodyExample;
                                _bodyController.text = ex != null
                                    ? const JsonEncoder.withIndent('  ')
                                        .convert(ex)
                                    : '{}';
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _bodyController,
                          maxLines: 8,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'application/json',
                            hintStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
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
                          style: FilledButton.styleFrom(
                              backgroundColor: mc),
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

                      // Response section
                      if (hasResponse) ...[
                        const SizedBox(height: 16),
                        // Response header row
                        Row(
                          children: [
                            _sectionLabel(l10n.apiExplorerResponse),
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
                                        color: _EndpointTile.responseColor(
                                            _responseStatus.toString()),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace')),
                              ),
                            ],
                            const Spacer(),
                            if (_binaryBody != null)
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    size: 16,
                                    color: AppColors.textSecondary),
                                tooltip: 'Copy as base64',
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(
                                        text: base64Encode(_binaryBody!))),
                              )
                            else if (_responseBody != null)
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    size: 16,
                                    color: AppColors.textSecondary),
                                tooltip: 'Copy',
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(text: _responseBody!)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Binary image preview
                        if (_binaryBody != null) ...[
                          Container(
                            width: double.infinity,
                            constraints:
                                const BoxConstraints(maxHeight: 340),
                            padding: const EdgeInsets.all(12),
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((_binaryContentType ?? '')
                                    .startsWith('image/'))
                                  Flexible(
                                    child: Center(
                                      child: Image.memory(
                                        _binaryBody!,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (_, error, __) => Padding(
                                          padding:
                                              const EdgeInsets.all(16),
                                          child: Text(
                                            'Failed to decode image: $error',
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_binaryContentType ?? 'binary'} · '
                                  '${(_binaryBody!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ]
                        // JSON / text response
                        else
                          Container(
                            width: double.infinity,
                            constraints:
                                const BoxConstraints(maxHeight: 220),
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13),
      );
}
