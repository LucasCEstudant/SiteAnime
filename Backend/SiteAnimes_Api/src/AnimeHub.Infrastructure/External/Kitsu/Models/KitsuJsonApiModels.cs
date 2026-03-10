namespace AnimeHub.Infrastructure.External.Kitsu.Models;

public sealed class KitsuRelationships
{
    public KitsuRelationshipData? Categories { get; set; }
}

public sealed class KitsuRelationshipData
{
    public List<KitsuResourceIdentifier>? Data { get; set; }
}

public sealed class KitsuResourceIdentifier
{
    public string? Type { get; set; }
    public string? Id { get; set; }
}

public sealed class KitsuIncludedResource
{
    public string? Type { get; set; }
    public string? Id { get; set; }
    public KitsuIncludedAttributes? Attributes { get; set; }
}

public sealed class KitsuIncludedAttributes
{
    public string? Title { get; set; }
}
