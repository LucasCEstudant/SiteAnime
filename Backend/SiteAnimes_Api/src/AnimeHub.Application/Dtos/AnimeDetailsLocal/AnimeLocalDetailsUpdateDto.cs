namespace AnimeHub.Application.Dtos.AnimeDetailsLocal;

public sealed record AnimeLocalDetailsUpdateDto(
    int? EpisodeCount,
    int? EpisodeLengthMinutes,
    List<AnimeLocalExternalLinkDto>? ExternalLinks,
    List<AnimeLocalStreamingEpisodeDto>? StreamingEpisodes
);