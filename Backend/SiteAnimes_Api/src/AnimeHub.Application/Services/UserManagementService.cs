using AnimeHub.Application.Dtos.Users;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Auth;

namespace AnimeHub.Application.Services;

public sealed class UserManagementService : IUserManagementService
{
    private readonly IUserRepository _users;

    public UserManagementService(IUserRepository users) => _users = users;

    public async Task<UserDto> CreateAsync(UserCreateDto dto, CancellationToken ct)
    {
        var email = dto.Email.Trim().ToLowerInvariant();

        var exists = await _users.GetByEmailAsync(email, ct);
        if (exists is not null)
            throw new InvalidOperationException("Já existe um usuário com este e-mail.");

        if (dto.Role is not (Roles.Admin or Roles.User))
            throw new InvalidOperationException("Role inválida.");

        var user = new User
        {
            Email = email,
            PasswordHash = PasswordHasher.Hash(dto.Password),
            Role = dto.Role,
            CreatedAtUtc = DateTime.UtcNow
        };

        var created = await _users.AddAsync(user, ct);

        return new UserDto(created.Id, created.Email, created.Role, created.CreatedAtUtc);
    }

    public async Task<List<UserDto>> GetAllAsync(CancellationToken ct)
    {
        var all = await _users.GetAllAsync(ct);
        return all.Select(u => new UserDto(u.Id, u.Email, u.Role, u.CreatedAtUtc)).ToList();
    }

    public async Task<UserDto?> GetByIdAsync(int id, CancellationToken ct)
    {
        var u = await _users.GetByIdAsync(id, ct);
        return u is null ? null : new UserDto(u.Id, u.Email, u.Role, u.CreatedAtUtc);
    }

    public async Task<bool> UpdateAsync(int id, UserUpdateDto dto, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(id, ct);
        if (user is null) return false;

        if (dto.Email is not null)
        {
            var email = dto.Email.Trim().ToLowerInvariant();

            // impede colisão de e-mail (se for mudar)
            if (!string.Equals(email, user.Email, StringComparison.OrdinalIgnoreCase))
            {
                var exists = await _users.GetByEmailAsync(email, ct);
                if (exists is not null)
                    throw new InvalidOperationException("Já existe um usuário com este e-mail.");

                user.Email = email;
            }
        }

        if (dto.Role is not null)
        {
            if (dto.Role is not (Roles.Admin or Roles.User))
                throw new InvalidOperationException("Role inválida.");

            user.Role = dto.Role;
        }

        if (dto.Password is not null)
        {
            user.PasswordHash = PasswordHasher.Hash(dto.Password);
        }

        await _users.UpdateAsync(user, ct);
        return true;
    }

    public async Task<bool> DeleteAsync(int id, CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(id, ct);
        if (user is null) return false;

        await _users.DeleteAsync(user, ct);
        return true;
    }
}