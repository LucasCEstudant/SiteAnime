namespace AnimeHub.Application.Dtos.Queries;

public sealed record AnimeDetailsQueryDto(
    string? Source,
    int? Id,
    string? ExternalId
);