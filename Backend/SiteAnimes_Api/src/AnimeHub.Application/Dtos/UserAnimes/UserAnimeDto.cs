namespace AnimeHub.Application.Dtos.UserAnimes;

public sealed record UserAnimeDto(
    int Id,
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider,
    string Title,
    int? Year,
    string? CoverUrl,
    string? Status,
    decimal? Score,
    int? EpisodesWatched,
    string? Notes,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);
