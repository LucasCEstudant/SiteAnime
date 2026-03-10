using AnimeHub.Application.Dtos.Users;

namespace AnimeHub.Application.Interfaces;

public interface IUserManagementService
{
    Task<UserDto> CreateAsync(UserCreateDto dto, CancellationToken ct);
    Task<List<UserDto>> GetAllAsync(CancellationToken ct);
    Task<UserDto?> GetByIdAsync(int id, CancellationToken ct);
    Task<bool> UpdateAsync(int id, UserUpdateDto dto, CancellationToken ct);
    Task<bool> DeleteAsync(int id, CancellationToken ct);
}