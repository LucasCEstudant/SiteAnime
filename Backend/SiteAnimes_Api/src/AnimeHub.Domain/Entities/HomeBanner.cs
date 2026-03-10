namespace AnimeHub.Domain.Entities;

public class HomeBanner
{
    public int Id { get; set; }
    public string Slot { get; set; } = "";

    public int? AnimeId { get; set; }
    public Anime? Anime { get; set; }

    public string? ExternalId { get; set; }
    public string? ExternalProvider { get; set; }

    public DateTime UpdatedAtUtc { get; set; }
}
