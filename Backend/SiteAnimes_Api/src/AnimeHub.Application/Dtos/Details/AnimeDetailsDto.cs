namespace AnimeHub.Application.Dtos.Details;

public sealed record AnimeDetailsDto(
    string Source,
    int? Id,
    string? ExternalId,
    string Title,
    string? Synopsis,
    int? Year,
    decimal? Score,
    string? CoverUrl,
    int? EpisodeCount,
    int? EpisodeLength,
    IReadOnlyList<string> Genres,
    IReadOnlyList<AnimeExternalLinkDto> ExternalLinks,
    IReadOnlyList<AnimeStreamingEpisodeDto> StreamingEpisodes
);

public sealed record AnimeExternalLinkDto(string Site, string Url);

public sealed record AnimeStreamingEpisodeDto(string Title, string Url, string? Site);
