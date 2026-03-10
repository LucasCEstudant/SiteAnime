/// DTO completo retornado por `GET /api/animes/details`.
class AnimeDetailsDto {
  AnimeDetailsDto({
    required this.source,
    this.id,
    this.externalId,
    required this.title,
    this.synopsis,
    this.year,
    this.score,
    this.coverUrl,
    this.episodeCount,
    this.episodeLength,
    required this.externalLinks,
    required this.streamingEpisodes,
    this.genres = const [],
  });

  final String source;
  final int? id;
  final String? externalId;
  final String title;
  final String? synopsis;
  final int? year;
  final double? score;
  final String? coverUrl;
  final int? episodeCount;
  final int? episodeLength;
  final List<AnimeExternalLinkDto> externalLinks;
  final List<AnimeStreamingEpisodeDto> streamingEpisodes;
  final List<String> genres;

  factory AnimeDetailsDto.fromJson(Map<String, dynamic> json) {
    return AnimeDetailsDto(
      source: json['source'] as String,
      id: json['id'] as int?,
      externalId: json['externalId'] as String?,
      title: json['title'] as String,
      synopsis: json['synopsis'] as String?,
      year: json['year'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      coverUrl: json['coverUrl'] as String?,
      episodeCount: json['episodeCount'] as int?,
      episodeLength: json['episodeLength'] as int?,
      externalLinks: (json['externalLinks'] as List<dynamic>?)
              ?.map(
                (e) =>
                    AnimeExternalLinkDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      streamingEpisodes: (json['streamingEpisodes'] as List<dynamic>?)
              ?.map(
                (e) => AnimeStreamingEpisodeDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Link externo (MAL, AniList, etc.).
class AnimeExternalLinkDto {
  const AnimeExternalLinkDto({required this.site, required this.url});

  final String site;
  final String url;

  factory AnimeExternalLinkDto.fromJson(Map<String, dynamic> json) {
    return AnimeExternalLinkDto(
      site: json['site'] as String,
      url: json['url'] as String,
    );
  }
}

/// Episódio de streaming disponível.
class AnimeStreamingEpisodeDto {
  const AnimeStreamingEpisodeDto({
    required this.title,
    required this.url,
    this.site,
  });

  final String title;
  final String url;
  final String? site;

  factory AnimeStreamingEpisodeDto.fromJson(Map<String, dynamic> json) {
    return AnimeStreamingEpisodeDto(
      title: json['title'] as String,
      url: json['url'] as String,
      site: json['site'] as String?,
    );
  }
}
