namespace AnimeHub.Infrastructure.External.AniList.Models;

public sealed class AniListGenresResponse
{
    public AniListGenresData? Data { get; set; }
}

public sealed class AniListGenresData
{
    public List<string>? GenreCollection { get; set; }
}