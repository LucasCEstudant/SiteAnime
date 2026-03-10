using AnimeHub.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AnimeHub.Infrastructure.Persistence.Configurations;

public class HomeBannerConfig : IEntityTypeConfiguration<HomeBanner>
{
    public void Configure(EntityTypeBuilder<HomeBanner> b)
    {
        b.ToTable("HomeBanners");
        b.HasKey(x => x.Id);

        b.Property(x => x.Slot).HasMaxLength(50).IsRequired();
        b.HasIndex(x => x.Slot).IsUnique();

        b.Property(x => x.ExternalId).HasMaxLength(100);
        b.Property(x => x.ExternalProvider).HasMaxLength(50);

        b.HasOne(x => x.Anime)
         .WithMany()
         .HasForeignKey(x => x.AnimeId)
         .OnDelete(DeleteBehavior.SetNull);
    }
}
