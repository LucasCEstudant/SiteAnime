import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

/// Resultado de um teste de API.
class _TestResult {
  const _TestResult({required this.label, required this.body, this.error});

  final String label;
  final String? body;
  final String? error;

  bool get isSuccess => error == null;
}

/// Provider que executa os testes de API ao ser lido.
final apiTestProvider = FutureProvider<List<_TestResult>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final results = <_TestResult>[];

  // --- Test 1: Health Live ---
  try {
    final res = await client.get<String>('/health/live');
    results.add(_TestResult(
      label: 'GET /health/live',
      body: 'Status ${res.statusCode}: ${res.data}',
    ));
  } on ApiException catch (e) {
    results.add(_TestResult(
      label: 'GET /health/live',
      body: null,
      error: e.message,
    ));
  }

  // --- Test 2: Genres (público) ---
  try {
    final res = await client.get<dynamic>('/api/meta/anilist/genres');
    final data = res.data;
    final preview = data is List
        ? '${data.length} gêneros: ${data.take(5).join(", ")}…'
        : data.toString();
    results.add(_TestResult(
      label: 'GET /api/meta/anilist/genres',
      body: 'Status ${res.statusCode}: $preview',
    ));
  } on ApiException catch (e) {
    results.add(_TestResult(
      label: 'GET /api/meta/anilist/genres',
      body: null,
      error: e.message,
    ));
  }

  return results;
});

/// Tela de teste de API – Etapa 3.
/// Mostra resultado de chamadas públicas para validar o ApiClient.
class ApiTestPage extends ConsumerWidget {
  const ApiTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncResults = ref.watch(apiTestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiTestTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.apiTestUnexpectedError(err.toString()),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (results) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (context2, index2) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final r = results[index];
            return Card(
              color: r.isSuccess
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          r.isSuccess ? Icons.check_circle : Icons.error,
                          color: r.isSuccess
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.isSuccess ? r.body! : r.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.apiTestRepeat,
        onPressed: () => ref.invalidate(apiTestProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
