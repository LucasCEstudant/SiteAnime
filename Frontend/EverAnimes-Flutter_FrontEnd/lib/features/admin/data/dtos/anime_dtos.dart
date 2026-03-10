// DTOs para o CRUD de animes admin — Etapa 14.

/// Link externo do anime (ex: site oficial).
class ExternalLinkDto {
  const ExternalLinkDto({required this.site, required this.url});

  final String site;
  final String url;

  factory ExternalLinkDto.fromJson(Map<String, dynamic> json) {
    return ExternalLinkDto(
      site: json['site'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'site': site, 'url': url};
}

/// Episódio em streaming.
class StreamingEpisodeDto {
  const StreamingEpisodeDto({
    required this.title,
    required this.url,
    this.site,
  });

  final String title;
  final String url;
  final String? site;

  factory StreamingEpisodeDto.fromJson(Map<String, dynamic> json) {
    return StreamingEpisodeDto(
      title: json['title'] as String,
      url: json['url'] as String,
      site: json['site'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title, 'url': url};
    if (site != null) map['site'] = site;
    return map;
  }
}

/// Resposta do GET /api/animes e GET /api/animes/{id}.
/// O backend retorna a entidade Anime diretamente (camelCase).
class AnimeDto {
  const AnimeDto({
    required this.id,
    required this.title,
    this.synopsis,
    this.year,
    this.status,
    this.score,
    this.coverUrl,
    this.episodeCount,
    this.episodeLengthMinutes,
    this.externalLinks = const [],
    this.streamingEpisodes = const [],
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final int id;
  final String title;
  final String? synopsis;
  final int? year;
  final String? status;
  final double? score;
  final String? coverUrl;
  final int? episodeCount;
  final int? episodeLengthMinutes;
  final List<ExternalLinkDto> externalLinks;
  final List<StreamingEpisodeDto> streamingEpisodes;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory AnimeDto.fromJson(Map<String, dynamic> json) {
    return AnimeDto(
      id: json['id'] as int,
      title: json['title'] as String,
      synopsis: json['synopsis'] as String?,
      year: json['year'] as int?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      coverUrl: json['coverUrl'] as String?,
      episodeCount: json['episodeCount'] as int?,
      episodeLengthMinutes: json['episodeLengthMinutes'] as int?,
      externalLinks: (json['externalLinks'] as List<dynamic>?)
              ?.map((e) =>
                  ExternalLinkDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      streamingEpisodes: (json['streamingEpisodes'] as List<dynamic>?)
              ?.map((e) =>
                  StreamingEpisodeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.parse(json['updatedAtUtc'] as String)
          : null,
    );
  }
}

/// Body do POST /api/animes.
class AnimeCreateDto {
  const AnimeCreateDto({
    required this.title,
    this.synopsis,
    this.year,
    this.status,
    this.score,
    this.coverUrl,
  });

  final String title;
  final String? synopsis;
  final int? year;
  final String? status;
  final double? score;
  final String? coverUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title};
    if (synopsis != null) map['synopsis'] = synopsis;
    if (year != null) map['year'] = year;
    if (status != null) map['status'] = status;
    if (score != null) map['score'] = score;
    if (coverUrl != null) map['coverUrl'] = coverUrl;
    return map;
  }
}

/// Body do PUT /api/animes/{id}.
/// Campos iguais ao AnimeCreateDto — title é obrigatório.
class AnimeUpdateDto {
  const AnimeUpdateDto({
    required this.title,
    this.synopsis,
    this.year,
    this.status,
    this.score,
    this.coverUrl,
  });

  final String title;
  final String? synopsis;
  final int? year;
  final String? status;
  final double? score;
  final String? coverUrl;

  Map<String, dynamic> toJson() => {
        'title': title,
        'synopsis': synopsis,
        'year': year,
        'status': status,
        'score': score,
        'coverUrl': coverUrl,
      };
}

/// Body do PUT /api/animes/{id}/details.
class AnimeLocalDetailsUpdateDto {
  const AnimeLocalDetailsUpdateDto({
    this.episodeCount,
    this.episodeLengthMinutes,
    this.externalLinks = const [],
    this.streamingEpisodes = const [],
  });

  final int? episodeCount;
  final int? episodeLengthMinutes;
  final List<ExternalLinkDto> externalLinks;
  final List<StreamingEpisodeDto> streamingEpisodes;

  Map<String, dynamic> toJson() => {
        'episodeCount': episodeCount,
        'episodeLengthMinutes': episodeLengthMinutes,
        'externalLinks': externalLinks.map((e) => e.toJson()).toList(),
        'streamingEpisodes':
            streamingEpisodes.map((e) => e.toJson()).toList(),
      };
}
