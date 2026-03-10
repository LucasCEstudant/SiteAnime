using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Dtos.Users;

namespace AnimeHub.Application.Interfaces;

public interface IRegisterService
{
    Task<UserDto> RegisterAsync(RegisterRequestDto dto, CancellationToken ct);
}