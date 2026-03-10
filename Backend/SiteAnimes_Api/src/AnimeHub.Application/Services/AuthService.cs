using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Auth;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _users;
        private readonly JwtTokenGenerator _jwt;
        private readonly JwtOptions _opt;
        private readonly AppDbContext _db;
        private readonly ILogger<AuthService> _logger;


        public AuthService(IUserRepository users,
                            JwtTokenGenerator jwt,
                            IOptions<JwtOptions> opt,
                            AppDbContext db,
                            ILogger<AuthService> logger)
        {
            _users = users;
            _jwt = jwt;
            _opt = opt.Value;
            _db = db;
            _logger = logger;
        }

        public async Task<AuthResponseDto?> LoginAsync(LoginRequestDto req, CancellationToken ct)
        {
            var email = req.Email.Trim().ToLowerInvariant();
            _logger.LogDebug("Auth login attempt. Email={Email}", email);

            var user = await _users.GetByEmailAsync(email, ct);
            if (user is null)
            {
                _logger.LogWarning("Auth login failed: user not found. Email={Email}", email);
                return null;
            }

            if (!PasswordHasher.Verify(req.Password, user.PasswordHash))
            {
                _logger.LogWarning("Auth login failed: invalid password. UserId={UserId} Email={Email}", user.Id, email);
                return null;
            }

            _logger.LogInformation("Auth login succeeded. UserId={UserId}", user.Id);

            var now = DateTime.UtcNow;

            var accessToken = _jwt.Create(user);
            var accessExpiresAtUtc = now.AddMinutes(_opt.ExpiresMinutes);

            var refreshTokenValue = RefreshTokenGenerator.Generate();
            var refreshExpiresAtUtc = now.AddDays(_opt.RefreshTokenExpiresDays);

            _db.RefreshTokens.Add(new RefreshToken
            {
                UserId = user.Id,
                Token = refreshTokenValue,
                CreatedAtUtc = now,
                ExpiresAtUtc = refreshExpiresAtUtc
            });

            await _db.SaveChangesAsync(ct);

            return new AuthResponseDto(accessToken, accessExpiresAtUtc, refreshTokenValue, refreshExpiresAtUtc);
        }

        public async Task<AuthResponseDto?> RefreshAsync(RefreshTokenRequestDto req, CancellationToken ct)
        {
            _logger.LogDebug("Auth refresh attempt.");

            var principal = _jwt.GetPrincipalFromExpiredToken(req.AccessToken);
            if (principal is null)
            {
                _logger.LogWarning("Auth refresh failed: invalid/expired access token.");
                return null;
            }

            var userId = _jwt.GetUserId(principal);
            if (userId is null)
            {
                _logger.LogWarning("Auth refresh failed: userId claim missing.");
                return null;
            }

            var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == userId, ct);
            if (user is null) return null;

            var storedRefresh = await _db.RefreshTokens
                .FirstOrDefaultAsync(x => x.Token == req.RefreshToken && x.UserId == userId, ct);

            if (storedRefresh is null)
            {
                _logger.LogWarning("Auth refresh failed: refresh token not found. UserId={UserId}", userId.Value);
                return null;
            }

            var now = DateTime.UtcNow;

            if (storedRefresh.RevokedAtUtc.HasValue)
            {
                _logger.LogWarning("Auth refresh failed: refresh token revoked. UserId={UserId}", userId.Value);
                return null;
            }

            if (storedRefresh.ExpiresAtUtc <= now)
            {
                _logger.LogWarning("Auth refresh failed: refresh token expired. UserId={UserId}", userId.Value);
                return null;
            }

            _logger.LogInformation("Auth refresh succeeded: rotating refresh token. UserId={UserId}", userId.Value);

            var newRefreshTokenValue = RefreshTokenGenerator.Generate();
            var newRefreshExpiresAtUtc = now.AddDays(_opt.RefreshTokenExpiresDays);

            storedRefresh.RevokedAtUtc = now;
            storedRefresh.ReplacedByToken = newRefreshTokenValue;

            _db.RefreshTokens.Add(new RefreshToken
            {
                UserId = user.Id,
                Token = newRefreshTokenValue,
                CreatedAtUtc = now,
                ExpiresAtUtc = newRefreshExpiresAtUtc
            });

            var newAccessToken = _jwt.Create(user);
            var newAccessExpiresAtUtc = now.AddMinutes(_opt.ExpiresMinutes);

            await _db.SaveChangesAsync(ct);

            return new AuthResponseDto(newAccessToken, newAccessExpiresAtUtc, newRefreshTokenValue, newRefreshExpiresAtUtc);
        }

        public async Task<bool> RevokeAsync(RevokeTokenRequestDto req, CancellationToken ct)
        {
            _logger.LogInformation("Auth revoke attempt.");

            var storedRefresh = await _db.RefreshTokens
                .FirstOrDefaultAsync(x => x.Token == req.RefreshToken, ct);

            if (storedRefresh is null)
            {
                _logger.LogWarning("Auth revoke failed: refresh token not found.");
                return false;
            }

            if (!storedRefresh.RevokedAtUtc.HasValue)
                storedRefresh.RevokedAtUtc = DateTime.UtcNow;

            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Auth revoke succeeded. RefreshTokenId={RefreshTokenId} UserId={UserId}",
                storedRefresh.Id, storedRefresh.UserId);

            return true;
        }
    }
}
