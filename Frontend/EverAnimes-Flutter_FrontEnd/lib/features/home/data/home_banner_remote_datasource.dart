import '../../../core/api/api_client.dart';
import 'dtos/home_banner_dto.dart';

/// Datasource remoto para banners da home.
///
/// Consome:
/// - `GET  /api/home/banners`       — lista banners (público)
/// - `PUT  /api/home/banners/{slot}` — atualiza banner (admin)
class HomeBannerRemoteDatasource {
  const HomeBannerRemoteDatasource(this._client);

  final ApiClient _client;

  /// Busca todos os banners configurados.
  Future<List<HomeBannerDto>> getAll() async {
    final response = await _client.get<List<dynamic>>('/api/home/banners');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(HomeBannerDto.fromJson)
        .toList();
  }

  /// Atualiza um banner pelo slot.
  Future<HomeBannerDto> update(String slot, HomeBannerUpdateDto dto) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/api/home/banners/$slot',
      data: dto.toJson(),
    );
    return HomeBannerDto.fromJson(response.data!);
  }
}
