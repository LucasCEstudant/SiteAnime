namespace AnimeHub.Application.Dtos.AnimeDetailsLocal;

public sealed record AnimeLocalDetailsDto(
    int Id,
    int? EpisodeCount,
    int? EpisodeLengthMinutes,
    IReadOnlyList<AnimeLocalExternalLinkDto> ExternalLinks,
    IReadOnlyList<AnimeLocalStreamingEpisodeDto> StreamingEpisodes
);

public sealed record AnimeLocalExternalLinkDto(string Site, string Url);
public sealed record AnimeLocalStreamingEpisodeDto(string Title, string Url, string? Site);
