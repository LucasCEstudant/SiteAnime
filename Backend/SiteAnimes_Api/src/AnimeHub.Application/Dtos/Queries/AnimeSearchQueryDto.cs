namespace AnimeHub.Application.Dtos.Queries;

public sealed record AnimeSearchQueryDto(
    string? Q,
    int? Limit,
    string? Cursor,
    int? Year,
    List<string>? Genres
);