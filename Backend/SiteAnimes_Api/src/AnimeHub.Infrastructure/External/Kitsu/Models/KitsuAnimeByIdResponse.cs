namespace AnimeHub.Infrastructure.External.Kitsu.Models;

public sealed class KitsuAnimeByIdResponse
{
    public KitsuAnimeResource? Data { get; set; }
    public List<KitsuIncludedResource>? Included { get; set; }
}