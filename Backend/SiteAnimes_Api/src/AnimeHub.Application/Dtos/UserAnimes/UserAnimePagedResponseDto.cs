namespace AnimeHub.Application.Dtos.UserAnimes;

public sealed record UserAnimePagedResponseDto(
    IReadOnlyList<UserAnimeDto> Items,
    int TotalCount,
    int Page,
    int PageSize
);
