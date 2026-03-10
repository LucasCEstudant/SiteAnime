using AnimeHub.Infrastructure.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace AnimeHub.Infrastructure.Persistence.Seed
{
    public static class DbSeeder
    {
        public static async Task SeedAsync(AppDbContext db, IConfiguration cfg, CancellationToken ct)
        {
            await db.Database.MigrateAsync(ct);

            var enabled = cfg.GetValue<bool>("SeedAdmin:Enabled");
            if (!enabled) return;

            var email = cfg["SeedAdmin:Email"]!;
            var password = cfg["SeedAdmin:Password"]!;

            var exists = await db.Users.AnyAsync(x => x.Email == email, ct);
            if (exists) return;

            db.Users.Add(new AnimeHub.Domain.Entities.User
            {
                Email = email,
                PasswordHash = PasswordHasher.Hash(password),
                Role = "Admin"
            });

            await db.SaveChangesAsync(ct);
        }
    }
}
