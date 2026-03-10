namespace AnimeHub.Application.Dtos.UserAnimes;

public sealed record UserAnimeCreateDto(
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider,
    string Title,
    int? Year,
    string? CoverUrl,
    string? Status,
    decimal? Score,
    int? EpisodesWatched,
    string? Notes
);
