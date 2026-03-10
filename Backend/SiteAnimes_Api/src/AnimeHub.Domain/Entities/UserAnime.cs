namespace AnimeHub.Domain.Entities;

public class UserAnime
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = default!;

    public int? AnimeId { get; set; }
    public Anime? Anime { get; set; }

    public string? ExternalId { get; set; }
    public string? ExternalProvider { get; set; }

    public string Title { get; set; } = "";
    public int? Year { get; set; }
    public string? CoverUrl { get; set; }

    public string? Status { get; set; }
    public decimal? Score { get; set; }
    public int? EpisodesWatched { get; set; }
    public string? Notes { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
}
