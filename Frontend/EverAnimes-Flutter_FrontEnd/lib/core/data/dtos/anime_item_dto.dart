/// Item individual retornado por vários endpoints da API (filtros, busca).
///
/// Estrutura comum a `FilterAnimeItemDto` e `SearchAnimeItemDto` no backend.
class AnimeItemDto {
  const AnimeItemDto({
    required this.source,
    this.id,
    this.externalId,
    required this.title,
    this.year,
    this.score,
    this.coverUrl,
    this.genres = const [],
  });

  factory AnimeItemDto.fromJson(Map<String, dynamic> json) {
    return AnimeItemDto(
      source: json['source'] as String? ?? 'Unknown',
      id: json['id'] as int?,
      externalId: json['externalId'] as String?,
      title: json['title'] as String? ?? '',
      year: json['year'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      coverUrl: json['coverUrl'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  final String source;
  final int? id;
  final String? externalId;
  final String title;
  final int? year;
  final double? score;
  final String? coverUrl;
  final List<String> genres;
}
