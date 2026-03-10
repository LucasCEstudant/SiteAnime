import '../data/details_remote_datasource.dart';
import '../data/dtos/anime_details_dto.dart';

/// Repository para detalhes de anime.
class DetailsRepository {
  DetailsRepository(this._datasource);

  final DetailsRemoteDatasource _datasource;

  /// Busca detalhes por [source] + ([id] ou [externalId]).
  Future<AnimeDetailsDto> getDetails({
    required String source,
    int? id,
    String? externalId,
  }) {
    return _datasource.fetchDetails(
      source: source,
      id: id,
      externalId: externalId,
    );
  }
}
