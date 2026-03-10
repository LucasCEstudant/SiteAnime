namespace AnimeHub.Application.Dtos.Queries;

public sealed record AnimeSeasonNowQueryDto(
    int? Limit,
    string? Cursor
);