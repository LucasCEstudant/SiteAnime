using AnimeHub.Infrastructure.External.Kitsu.Models;

namespace AnimeHub.Infrastructure.External.Kitsu;

public static class KitsuCategoryHelper
{
    public static IReadOnlyList<string> ExtractCategories(
        KitsuAnimeResource? resource,
        List<KitsuIncludedResource>? included)
    {
        if (resource?.Relationships?.Categories?.Data is null || included is null)
            return [];

        var catIds = resource.Relationships.Categories.Data
            .Where(x => x.Id is not null)
            .Select(x => x.Id!)
            .ToHashSet();

        return included
            .Where(x => string.Equals(x.Type, "categories", StringComparison.OrdinalIgnoreCase)
                     && x.Id is not null && catIds.Contains(x.Id))
            .Select(x => x.Attributes?.Title)
            .Where(t => !string.IsNullOrWhiteSpace(t))
            .Select(t => t!)
            .ToList();
    }
}
