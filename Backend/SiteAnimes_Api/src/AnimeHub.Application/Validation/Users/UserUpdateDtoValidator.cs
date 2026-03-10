using AnimeHub.Application.Dtos.Users;
using AnimeHub.Domain.Entities;
using FluentValidation;

namespace AnimeHub.Application.Validation.Users;

public sealed class UserUpdateDtoValidator : AbstractValidator<UserUpdateDto>
{
    public UserUpdateDtoValidator()
    {
        When(x => x.Email is not null, () =>
        {
            RuleFor(x => x.Email!)
                .NotEmpty()
                .EmailAddress()
                .MaximumLength(200);
        });

        When(x => x.Password is not null, () =>
        {
            RuleFor(x => x.Password!)
                .NotEmpty()
                .MinimumLength(6)
                .MaximumLength(200);
        });

        When(x => x.Role is not null, () =>
        {
            RuleFor(x => x.Role!)
                .NotEmpty()
                .Must(r => r == Roles.Admin || r == Roles.User)
                .WithMessage($"Role inválida. Use '{Roles.Admin}' ou '{Roles.User}'.");
        });

        RuleFor(x => x)
            .Must(x => x.Email is not null || x.Password is not null || x.Role is not null)
            .WithMessage("Informe ao menos um campo para atualizar (email, password, role).");
    }
}