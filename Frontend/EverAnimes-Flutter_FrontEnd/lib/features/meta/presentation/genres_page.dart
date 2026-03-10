import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/error_view.dart';
import '../../../widgets/top_header.dart';
import 'meta_providers.dart';

/// Tela que exibe a lista de gêneros vindos da API.
/// Etapa 4: prova de integração ponta a ponta
/// DTO → datasource → repository → provider → UI.
///
/// Ao clicar em um gênero, navega para a página de Busca já filtrada.
class GenresPage extends ConsumerWidget {
  const GenresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncGenres = ref.watch(genresProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: kTopHeaderHeight),
        child: asyncGenres.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          fallbackMessage: l10n.genresLoadError,
          onRetry: () => ref.invalidate(genresProvider),
        ),
        data: (genres) => genres.isEmpty
            ? Center(child: Text(l10n.genresEmpty))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        genre[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(genre),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push(
                        '/search?genre=${Uri.encodeComponent(genre)}',
                      );
                    },
                  );
                },
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.reload,
        onPressed: () => ref.invalidate(genresProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
