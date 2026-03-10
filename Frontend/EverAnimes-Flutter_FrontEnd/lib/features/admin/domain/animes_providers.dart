import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/dtos/anime_dtos.dart';
import '../data/animes_remote_datasource.dart';

/// Provider do datasource de animes.
final animesDatasourceProvider = Provider<AnimesRemoteDatasource>((ref) {
  return AnimesRemoteDatasource(ref.read(apiClientProvider));
});

/// Provider que carrega a lista de animes.
/// Pode ser invalidado para forçar reload.
final animesListProvider = FutureProvider<List<AnimeDto>>((ref) async {
  final datasource = ref.read(animesDatasourceProvider);
  return datasource.getAll();
});
