using AnimeHub.Application.Dtos.Auth;
using FluentValidation;

namespace AnimeHub.Application.Validation.Auth;

public sealed class RevokeTokenRequestDtoValidator : AbstractValidator<RevokeTokenRequestDto>
{
    public RevokeTokenRequestDtoValidator()
    {
        RuleFor(x => x.RefreshToken).NotEmpty();
    }
}