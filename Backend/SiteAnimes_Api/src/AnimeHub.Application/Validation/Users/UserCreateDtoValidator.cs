using AnimeHub.Application.Dtos.Users;
using AnimeHub.Domain.Entities;
using FluentValidation;

namespace AnimeHub.Application.Validation.Users;

public sealed class UserCreateDtoValidator : AbstractValidator<UserCreateDto>
{
    public UserCreateDtoValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(200);

        RuleFor(x => x.Password)
            .NotEmpty()
            .MinimumLength(6)
            .MaximumLength(200);

        RuleFor(x => x.Role)
            .NotEmpty()
            .Must(r => r == Roles.Admin || r == Roles.User)
            .WithMessage($"Role inválida. Use '{Roles.Admin}' ou '{Roles.User}'.");
    }
}