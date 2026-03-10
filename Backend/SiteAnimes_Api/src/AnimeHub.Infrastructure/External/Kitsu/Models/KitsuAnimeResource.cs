namespace AnimeHub.Infrastructure.External.Kitsu.Models;

public sealed class KitsuAnimeResource
{
    public string? Id { get; set; }
    public KitsuAttributes? Attributes { get; set; }
    public KitsuRelationships? Relationships { get; set; }
}