namespace AnimeHub.Domain.Entities
{
    public class Anime
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string? Synopsis { get; set; }
        public int? Year { get; set; }
        public string? Status { get; set; }

        public decimal? Score { get; set; }
        public string? CoverUrl { get; set; }

        public int? EpisodeCount { get; set; }
        public int? EpisodeLengthMinutes { get; set; }

        public List<AnimeExternalLink> ExternalLinks { get; set; } = new();
        public List<AnimeStreamingEpisode> StreamingEpisodes { get; set; } = new();

        public DateTime CreatedAtUtc { get; set; }
        public DateTime? UpdatedAtUtc { get; set; }
    }

    public sealed class AnimeExternalLink
    {
        public string Site { get; set; } = "";
        public string Url { get; set; } = "";
    }

    public sealed class AnimeStreamingEpisode
    {
        public string Title { get; set; } = "";
        public string Url { get; set; } = "";
        public string? Site { get; set; }
    }
}
