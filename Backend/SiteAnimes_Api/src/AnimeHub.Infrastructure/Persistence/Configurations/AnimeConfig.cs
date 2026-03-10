using System.Linq;
using System.Text.Json;
using AnimeHub.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace AnimeHub.Infrastructure.Persistence.Configurations
{
    public class AnimeConfig : IEntityTypeConfiguration<Anime>
    {
        public void Configure(EntityTypeBuilder<Anime> builder)
        {
            builder.ToTable("Animes");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Title).HasMaxLength(200).IsRequired();
            builder.Property(x => x.Score).HasPrecision(4, 2);
            builder.Property(x => x.Status).HasMaxLength(50);

            builder.HasIndex(x => new { x.Title, x.Id });

            builder.Property(x => x.EpisodeCount);
            builder.Property(x => x.EpisodeLengthMinutes);

            var jsonOptions = new JsonSerializerOptions(JsonSerializerDefaults.Web);

            // ---------------- ValueComparer(s) ----------------
            var externalLinksComparer = new ValueComparer<List<AnimeExternalLink>>(
                (a, b) => (a ?? new()).SequenceEqual(b ?? new(), AnimeExternalLinkEqualityComparer.Instance),
                v => (v ?? new()).Aggregate(0, (h, x) => HashCode.Combine(h, AnimeExternalLinkEqualityComparer.Instance.GetHashCode(x))),
                v => (v ?? new()).Select(x => new AnimeExternalLink { Site = x.Site, Url = x.Url }).ToList()
            );

            var streamingEpisodesComparer = new ValueComparer<List<AnimeStreamingEpisode>>(
                (a, b) => (a ?? new()).SequenceEqual(b ?? new(), AnimeStreamingEpisodeEqualityComparer.Instance),
                v => (v ?? new()).Aggregate(0, (h, x) => HashCode.Combine(h, AnimeStreamingEpisodeEqualityComparer.Instance.GetHashCode(x))),
                v => (v ?? new()).Select(x => new AnimeStreamingEpisode { Title = x.Title, Url = x.Url, Site = x.Site }).ToList()
            );

            // ---------------- Converters + Comparers ----------------
            builder.Property(x => x.ExternalLinks)
                .HasConversion(new ValueConverter<List<AnimeExternalLink>, string>(
                    v => JsonSerializer.Serialize(v ?? new(), jsonOptions),
                    v => string.IsNullOrWhiteSpace(v)
                        ? new List<AnimeExternalLink>()
                        : JsonSerializer.Deserialize<List<AnimeExternalLink>>(v, jsonOptions) ?? new()
                ))
                .Metadata.SetValueComparer(externalLinksComparer);

            builder.Property(x => x.StreamingEpisodes)
                .HasConversion(new ValueConverter<List<AnimeStreamingEpisode>, string>(
                    v => JsonSerializer.Serialize(v ?? new(), jsonOptions),
                    v => string.IsNullOrWhiteSpace(v)
                        ? new List<AnimeStreamingEpisode>()
                        : JsonSerializer.Deserialize<List<AnimeStreamingEpisode>>(v, jsonOptions) ?? new()
                ))
                .Metadata.SetValueComparer(streamingEpisodesComparer);
        }

        // Comparers de item (pra SequenceEqual ficar correto)
        private sealed class AnimeExternalLinkEqualityComparer : IEqualityComparer<AnimeExternalLink>
        {
            public static readonly AnimeExternalLinkEqualityComparer Instance = new();
            public bool Equals(AnimeExternalLink? x, AnimeExternalLink? y)
                => string.Equals(x?.Site, y?.Site, StringComparison.Ordinal)
                && string.Equals(x?.Url, y?.Url, StringComparison.Ordinal);

            public int GetHashCode(AnimeExternalLink obj)
                => HashCode.Combine(obj.Site ?? "", obj.Url ?? "");
        }

        private sealed class AnimeStreamingEpisodeEqualityComparer : IEqualityComparer<AnimeStreamingEpisode>
        {
            public static readonly AnimeStreamingEpisodeEqualityComparer Instance = new();
            public bool Equals(AnimeStreamingEpisode? x, AnimeStreamingEpisode? y)
                => string.Equals(x?.Title, y?.Title, StringComparison.Ordinal)
                && string.Equals(x?.Url, y?.Url, StringComparison.Ordinal)
                && string.Equals(x?.Site, y?.Site, StringComparison.Ordinal);

            public int GetHashCode(AnimeStreamingEpisode obj)
                => HashCode.Combine(obj.Title ?? "", obj.Url ?? "", obj.Site ?? "");
        }
    }
}