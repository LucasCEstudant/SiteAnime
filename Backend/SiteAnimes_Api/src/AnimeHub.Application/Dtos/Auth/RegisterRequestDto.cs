namespace AnimeHub.Application.Dtos.Auth;

public sealed record RegisterRequestDto(
    string Email,
    string Password
);