
namespace AnimeHub.Domain.Entities
{
    public class RefreshToken
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public string Token { get; set; } = string.Empty;

        public DateTime ExpiresAtUtc { get; set; }
        public DateTime CreatedAtUtc { get; set; }

        public DateTime? RevokedAtUtc { get; set; }
        public string? ReplacedByToken { get; set; }

        // para auditoria
        public string? CreatedByIp { get; set; }
        public string? RevokedByIp { get; set; }

        // navegação
        public User User { get; set; } = null!;

        public bool IsExpired => DateTime.UtcNow >= ExpiresAtUtc;
        public bool IsRevoked => RevokedAtUtc.HasValue;
        public bool IsActive => !IsExpired && !IsRevoked;
    }
}

