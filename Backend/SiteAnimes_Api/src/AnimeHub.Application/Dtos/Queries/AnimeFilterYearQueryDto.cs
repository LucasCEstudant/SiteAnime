namespace AnimeHub.Application.Dtos.Queries;

public sealed record AnimeFilterYearQueryDto(
    int? Year,
    int? Limit,
    string? Cursor
);