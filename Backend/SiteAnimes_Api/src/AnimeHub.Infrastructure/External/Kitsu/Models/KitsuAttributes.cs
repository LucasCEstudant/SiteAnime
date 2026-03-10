namespace AnimeHub.Infrastructure.External.Kitsu.Models;

public sealed class KitsuAttributes
{
    public string? CanonicalTitle { get; set; }
    public string? Synopsis { get; set; }
    public string? StartDate { get; set; }
    public string? AverageRating { get; set; }
    public int? EpisodeCount { get; set; }
    public int? EpisodeLength { get; set; }
    public string? YoutubeVideoId { get; set; }
    public KitsuPosterImage? PosterImage { get; set; }
}