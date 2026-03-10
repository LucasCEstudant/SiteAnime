namespace AnimeHub.Application.Dtos.Users;

public sealed record UserUpdateDto(
    string? Email,
    string? Password,
    string? Role
);