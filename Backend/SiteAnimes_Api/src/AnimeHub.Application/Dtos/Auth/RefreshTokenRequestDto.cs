namespace AnimeHub.Application.Dtos.Auth
{
    public record RefreshTokenRequestDto(
        string AccessToken,
        string RefreshToken
    );
}
