namespace AnimeHub.Application.Dtos.HomeBanners;

public sealed record HomeBannerUpdateDto(
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider
);
