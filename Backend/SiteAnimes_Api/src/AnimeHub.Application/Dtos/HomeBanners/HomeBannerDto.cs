namespace AnimeHub.Application.Dtos.HomeBanners;

public sealed record HomeBannerDto(
    string Slot,
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider
);
