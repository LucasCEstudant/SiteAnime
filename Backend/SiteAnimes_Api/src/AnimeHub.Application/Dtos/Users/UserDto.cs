namespace AnimeHub.Application.Dtos.Users;

public sealed record UserDto(
    int Id,
    string Email,
    string Role,
    DateTime CreatedAtUtc
);