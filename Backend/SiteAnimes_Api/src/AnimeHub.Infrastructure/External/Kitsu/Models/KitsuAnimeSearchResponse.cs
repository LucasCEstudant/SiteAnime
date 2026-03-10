namespace AnimeHub.Infrastructure.External.Kitsu.Models;

public sealed class KitsuAnimeSearchResponse
{
    public List<KitsuAnimeResource>? Data { get; set; }
    public List<KitsuIncludedResource>? Included { get; set; }
}