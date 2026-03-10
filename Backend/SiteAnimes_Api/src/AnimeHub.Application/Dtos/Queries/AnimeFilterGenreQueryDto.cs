namespace AnimeHub.Application.Dtos.Queries;

public sealed record AnimeFilterGenreQueryDto(
    string? Genre,
    int? Limit,
    string? Cursor
);