namespace AnimeHub.Infrastructure.External.Kitsu.Queries;

public static class KitsuQueryRequests
{
    public static string SearchByText(string q, int offset, int limit)
        => $"anime?filter[text]={Uri.EscapeDataString(q)}&page%5Blimit%5D={limit}&page%5Boffset%5D={offset}&include=categories";

    public static string SearchByCategory(string categorySlug, int offset, int limit)
        => $"anime?filter[categories]={Uri.EscapeDataString(categorySlug)}&page%5Blimit%5D={limit}&page%5Boffset%5D={offset}&include=categories";

    public static string GetById(string id)
        => $"anime/{Uri.EscapeDataString(id)}?include=categories";
}