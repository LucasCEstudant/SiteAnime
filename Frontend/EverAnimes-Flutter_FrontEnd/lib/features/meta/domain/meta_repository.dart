import '../data/meta_remote_datasource.dart';

/// Repository de metadados.
/// Etapa 4: repassa ao datasource sem cache local.
/// Etapa futura: adicionar cache em memória / SharedPreferences.
class MetaRepository {
  const MetaRepository(this._datasource);

  final MetaRemoteDatasource _datasource;

  /// Retorna lista de gêneros disponíveis.
  Future<List<String>> getGenres() async {
    final response = await _datasource.fetchGenres();
    return response.genres;
  }
}
