/// Resposta do endpoint `GET /api/meta/anilist/genres`.
///
/// A API retorna um JSON array simples de strings: `["Action", "Adventure", ...]`.
/// Esta classe encapsula a lista para manter o padrão DTO → Repository → Provider.
class GenresResponse {
  const GenresResponse({required this.genres});

  /// Factory a partir do JSON decodificado (`List<dynamic>`).
  factory GenresResponse.fromJson(List<dynamic> json) {
    return GenresResponse(
      genres: json.map((e) => e as String).toList(growable: false),
    );
  }

  final List<String> genres;
}
