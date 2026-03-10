namespace AnimeHub.Application.Dtos.UserAnimes;

public sealed record UserAnimeUpdateDto(
    string? Status,
    decimal? Score,
    int? EpisodesWatched,
    string? Notes
);
