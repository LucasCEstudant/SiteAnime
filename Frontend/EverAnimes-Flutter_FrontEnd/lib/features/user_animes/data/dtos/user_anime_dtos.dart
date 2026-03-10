/// DTO for creating a new user anime entry.
/// Maps to `UserAnimeCreateDto` on the backend.
class UserAnimeCreateDto {
  const UserAnimeCreateDto({
    this.animeId,
    this.externalId,
    this.externalProvider,
    required this.title,
    this.year,
    this.coverUrl,
    this.status,
    this.score,
    this.episodesWatched,
    this.notes,
  });

  final int? animeId;
  final String? externalId;
  final String? externalProvider;
  final String title;
  final int? year;
  final String? coverUrl;
  final String? status;
  final double? score;
  final int? episodesWatched;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (animeId != null) 'animeId': animeId,
      if (externalId != null) 'externalId': externalId,
      if (externalProvider != null) 'externalProvider': externalProvider,
      'title': title,
      if (year != null) 'year': year,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (episodesWatched != null) 'episodesWatched': episodesWatched,
      if (notes != null) 'notes': notes,
    };
  }
}

/// DTO for updating an existing user anime entry (partial update).
class UserAnimeUpdateDto {
  const UserAnimeUpdateDto({
    this.status,
    this.score,
    this.episodesWatched,
    this.notes,
  });

  final String? status;
  final double? score;
  final int? episodesWatched;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (episodesWatched != null) 'episodesWatched': episodesWatched,
      if (notes != null) 'notes': notes,
    };
  }
}

/// DTO representing a user anime item (response from API).
class UserAnimeDto {
  const UserAnimeDto({
    required this.id,
    this.animeId,
    this.externalId,
    this.externalProvider,
    required this.title,
    this.year,
    this.coverUrl,
    this.status,
    this.score,
    this.episodesWatched,
    this.notes,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory UserAnimeDto.fromJson(Map<String, dynamic> json) {
    return UserAnimeDto(
      id: json['id'] as int,
      animeId: json['animeId'] as int?,
      externalId: json['externalId'] as String?,
      externalProvider: json['externalProvider'] as String?,
      title: json['title'] as String? ?? '',
      year: json['year'] as int?,
      coverUrl: json['coverUrl'] as String?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      episodesWatched: json['episodesWatched'] as int?,
      notes: json['notes'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.parse(json['updatedAtUtc'] as String)
          : null,
    );
  }

  final int id;
  final int? animeId;
  final String? externalId;
  final String? externalProvider;
  final String title;
  final int? year;
  final String? coverUrl;
  final String? status;
  final double? score;
  final int? episodesWatched;
  final String? notes;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
}

/// Paginated response for user anime list.
class UserAnimePagedResponseDto {
  const UserAnimePagedResponseDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory UserAnimePagedResponseDto.fromJson(Map<String, dynamic> json) {
    return UserAnimePagedResponseDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => UserAnimeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  final List<UserAnimeDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;
}
