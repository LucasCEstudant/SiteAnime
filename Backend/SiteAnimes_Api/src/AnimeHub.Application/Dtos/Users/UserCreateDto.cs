namespace AnimeHub.Application.Dtos.Users;

public sealed record UserCreateDto(
    string Email,
    string Password,
    string Role
);