
namespace AnimeHub.Infrastructure.Auth
{
    public class JwtOptions
    {
        public string Issuer { get; init; } = default!;
        public string Audience { get; init; } = default!;
        public string Key { get; init; } = default!;
        public int ExpiresMinutes { get; init; } = 60;
        public int RefreshTokenExpiresDays { get; set; } = 7;
    }
}
