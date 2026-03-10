import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/meta_remote_datasource.dart';
import '../domain/meta_repository.dart';

/// Provider do datasource de metadados.
final metaDatasourceProvider = Provider<MetaRemoteDatasource>((ref) {
  return MetaRemoteDatasource(ref.watch(apiClientProvider));
});

/// Provider do repository de metadados.
final metaRepositoryProvider = Provider<MetaRepository>((ref) {
  return MetaRepository(ref.watch(metaDatasourceProvider));
});

/// Provider assíncrono que expõe a lista de gêneros.
/// Recarrega automaticamente se invalidado.
final genresProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(metaRepositoryProvider).getGenres();
});
