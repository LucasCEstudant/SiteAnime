namespace AnimeHub.Application.Dtos.Auth
{
    public record AuthResponseDto(
        string AccessToken,
        DateTime AccessTokenExpiresAtUtc,
        string? RefreshToken = null,
        DateTime? RefreshTokenExpiresAtUtc = null
    );
}
