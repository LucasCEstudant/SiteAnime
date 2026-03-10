import '../data/dtos/user_anime_dtos.dart';
import '../data/user_animes_remote_datasource.dart';

/// Repositório de alto nível para operações de UserAnimes.
///
/// Hoje é um pass-through fino sobre o datasource, mas isola
/// a camada de apresentação da camada de dados.
class UserAnimesRepository {
  const UserAnimesRepository(this._datasource);

  final UserAnimesRemoteDatasource _datasource;

  Future<UserAnimeDto> add(UserAnimeCreateDto dto) => _datasource.add(dto);

  Future<bool> existsByAnimeId(int animeId) =>
      _datasource.existsByAnimeId(animeId);

  Future<UserAnimePagedResponseDto> getAll({
    String? status,
    int? year,
    int page = 1,
    int pageSize = 20,
  }) =>
      _datasource.getAll(
        status: status,
        year: year,
        page: page,
        pageSize: pageSize,
      );

  Future<void> update(int id, UserAnimeUpdateDto dto) =>
      _datasource.update(id, dto);

  Future<void> delete(int id) => _datasource.delete(id);
}
