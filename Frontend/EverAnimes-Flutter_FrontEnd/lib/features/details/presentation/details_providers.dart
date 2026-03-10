import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/details_remote_datasource.dart';
import '../data/dtos/anime_details_dto.dart';
import '../domain/details_repository.dart';

/// Parâmetros necessários para buscar detalhes de um anime.
/// Usados como família (family) no provider.
typedef DetailsParams = ({String source, int? id, String? externalId});

/// Provider do datasource.
final _detailsDatasourceProvider = Provider<DetailsRemoteDatasource>((ref) {
  return DetailsRemoteDatasource(ref.watch(apiClientProvider));
});

/// Provider do repository.
final _detailsRepositoryProvider = Provider<DetailsRepository>((ref) {
  return DetailsRepository(ref.watch(_detailsDatasourceProvider));
});

/// Provider family que busca os detalhes por [DetailsParams].
///
/// Exemplo de uso:
/// ```dart
/// final details = ref.watch(
///   animeDetailsProvider((source: 'Kitsu', id: null, externalId: '11')),
/// );
/// ```
final animeDetailsProvider =
    FutureProvider.family<AnimeDetailsDto, DetailsParams>((ref, params) {
  final repo = ref.watch(_detailsRepositoryProvider);
  return repo.getDetails(
    source: params.source,
    id: params.id,
    externalId: params.externalId,
  );
});
