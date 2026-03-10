namespace AnimeHub.Infrastructure.External.AniList.Models;

public sealed class AniListMediaByIdResponse
{
    public AniListMediaByIdData? Data { get; set; }
}

public sealed class AniListMediaByIdData
{
    public AniListMediaDetails? Media { get; set; }
}

public sealed class AniListMediaDetails
{
    public int Id { get; set; }
    public AniListTitle? Title { get; set; }
    public string? Description { get; set; }
    public AniListStartDate? StartDate { get; set; }
    public int? AverageScore { get; set; } // 0-100
    public int? Episodes { get; set; }
    public int? Duration { get; set; } // min
    public AniListCover? CoverImage { get; set; }
    public List<string>? Genres { get; set; }

    public List<AniListExternalLink>? ExternalLinks { get; set; }
    public List<AniListStreamingEpisode>? StreamingEpisodes { get; set; }
}

public sealed class AniListExternalLink
{
    public string? Site { get; set; }
    public string? Url { get; set; }
}

public sealed class AniListStreamingEpisode
{
    public string? Title { get; set; }
    public string? Url { get; set; }
    public string? Site { get; set; }
}