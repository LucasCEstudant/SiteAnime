using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Dtos.Users;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Auth;

namespace AnimeHub.Application.Services;

public sealed class RegisterService : IRegisterService
{
    private readonly IUserRepository _users;

    public RegisterService(IUserRepository users) => _users = users;

    public async Task<UserDto> RegisterAsync(RegisterRequestDto dto, CancellationToken ct)
    {
        var email = dto.Email.Trim().ToLowerInvariant();

        var exists = await _users.GetByEmailAsync(email, ct);
        if (exists is not null)
            throw new EmailAlreadyRegisteredException(email);

        var user = new User
        {
            Email = email,
            PasswordHash = PasswordHasher.Hash(dto.Password),
            Role = Roles.User,
            CreatedAtUtc = DateTime.UtcNow
        };

        var created = await _users.AddAsync(user, ct);

        return new UserDto(created.Id, created.Email, created.Role, created.CreatedAtUtc);
    }
}

public sealed class EmailAlreadyRegisteredException : Exception
{
    public string Email { get; }
    public EmailAlreadyRegisteredException(string email)
        : base("E-mail já cadastrado.")
    {
        Email = email;
    }
}