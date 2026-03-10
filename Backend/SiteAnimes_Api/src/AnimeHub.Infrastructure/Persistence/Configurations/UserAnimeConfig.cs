using AnimeHub.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AnimeHub.Infrastructure.Persistence.Configurations;

public class UserAnimeConfig : IEntityTypeConfiguration<UserAnime>
{
    public void Configure(EntityTypeBuilder<UserAnime> b)
    {
        b.ToTable("UserAnimes");
        b.HasKey(x => x.Id);

        b.Property(x => x.Title).HasMaxLength(250).IsRequired();
        b.Property(x => x.ExternalId).HasMaxLength(100);
        b.Property(x => x.ExternalProvider).HasMaxLength(50);
        b.Property(x => x.CoverUrl).HasMaxLength(500);
        b.Property(x => x.Status).HasMaxLength(20);
        b.Property(x => x.Notes).HasMaxLength(2000);
        b.Property(x => x.Score).HasPrecision(4, 2).HasColumnType("decimal(4,2)");

        b.HasOne(x => x.User)
         .WithMany()
         .HasForeignKey(x => x.UserId)
         .OnDelete(DeleteBehavior.Cascade);

        b.HasOne(x => x.Anime)
         .WithMany()
         .HasForeignKey(x => x.AnimeId)
         .OnDelete(DeleteBehavior.SetNull);

        b.HasIndex(x => x.UserId);
        b.HasIndex(x => new { x.UserId, x.AnimeId });
        b.HasIndex(x => new { x.UserId, x.ExternalProvider, x.ExternalId });
        b.HasIndex(x => new { x.UserId, x.Year });
    }
}
