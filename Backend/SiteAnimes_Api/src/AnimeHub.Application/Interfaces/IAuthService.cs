using AnimeHub.Application.Dtos.Auth;

namespace AnimeHub.Application.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponseDto?> LoginAsync(LoginRequestDto req, CancellationToken ct);
        Task<AuthResponseDto?> RefreshAsync(RefreshTokenRequestDto req, CancellationToken ct);
        Task<bool> RevokeAsync(RevokeTokenRequestDto req, CancellationToken ct);
    }
}
