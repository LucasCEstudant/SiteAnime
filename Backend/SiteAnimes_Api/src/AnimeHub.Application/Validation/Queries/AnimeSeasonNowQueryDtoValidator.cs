using AnimeHub.Application.Dtos.Queries;
using FluentValidation;

namespace AnimeHub.Application.Validation.Queries;

public sealed class AnimeSeasonNowQueryDtoValidator : AbstractValidator<AnimeSeasonNowQueryDto>
{
    public AnimeSeasonNowQueryDtoValidator()
    {
        RuleFor(x => x.Limit)
            .NotNull()
            .InclusiveBetween(1, 50);
    }
}