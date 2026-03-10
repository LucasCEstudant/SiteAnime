/// DTO que representa um banner da home retornado por `GET /api/home/banners`.
class HomeBannerDto {
  const HomeBannerDto({
    required this.slot,
    this.animeId,
    this.externalId,
    this.externalProvider,
  });

  factory HomeBannerDto.fromJson(Map<String, dynamic> json) {
    return HomeBannerDto(
      slot: json['slot'] as String,
      animeId: json['animeId'] as int?,
      externalId: json['externalId'] as String?,
      externalProvider: json['externalProvider'] as String?,
    );
  }

  final String slot;
  final int? animeId;
  final String? externalId;
  final String? externalProvider;

  /// Indica se este banner aponta para um anime local.
  bool get isLocal => animeId != null;

  /// Indica se este banner aponta para um anime externo.
  bool get isExternal => externalId != null && externalProvider != null;

  Map<String, dynamic> toJson() => {
        'slot': slot,
        if (animeId != null) 'animeId': animeId,
        if (externalId != null) 'externalId': externalId,
        if (externalProvider != null) 'externalProvider': externalProvider,
      };
}

/// DTO para atualização de banner via `PUT /api/home/banners/{slot}`.
class HomeBannerUpdateDto {
  const HomeBannerUpdateDto({
    this.animeId,
    this.externalId,
    this.externalProvider,
  });

  final int? animeId;
  final String? externalId;
  final String? externalProvider;

  Map<String, dynamic> toJson() => {
        if (animeId != null) 'animeId': animeId,
        if (externalId != null) 'externalId': externalId,
        if (externalProvider != null) 'externalProvider': externalProvider,
      };
}
