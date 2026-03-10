using AnimeHub.Domain.Entities;
using AnimeHub.Infrastructure.Persistence.Configurations;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Infrastructure.Persistence
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Anime> Animes => Set<Anime>();
        public DbSet<User> Users => Set<User>();
        public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
        public DbSet<UserAnime> UserAnimes => Set<UserAnime>();
        public DbSet<HomeBanner> HomeBanners => Set<HomeBanner>();


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
            modelBuilder.ApplyConfiguration(new RefreshTokenConfig());
        }
    }
}
