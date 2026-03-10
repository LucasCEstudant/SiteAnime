namespace AnimeHub.Infrastructure.External.AniList.Models;

public sealed class AniListSearchResponse
{
    public AniListData? Data { get; set; }
}

public sealed class AniListData
{
    public AniListPage? Page { get; set; }
}

public sealed class AniListPage
{
    public List<AniListMedia>? Media { get; set; }
}

public sealed class AniListMedia
{
    public int Id { get; set; }
    public AniListTitle? Title { get; set; }
    public string? Description { get; set; }
    public AniListStartDate? StartDate { get; set; }
    public int? AverageScore { get; set; } // 0-100
    public AniListCover? CoverImage { get; set; }
    public List<string>? Genres { get; set; }
}

public sealed class AniListTitle { public string? UserPreferred { get; set; } }
public sealed class AniListStartDate { public int? Year { get; set; } }
public sealed class AniListCover { public string? Large { get; set; } }