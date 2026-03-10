using AnimeHub.Application.Dtos.Queries;
using FluentValidation;

namespace AnimeHub.Application.Validation.Queries;

public sealed class AnimeFilterYearQueryDtoValidator : AbstractValidator<AnimeFilterYearQueryDto>
{
    public AnimeFilterYearQueryDtoValidator()
    {
        RuleFor(x => x.Year)
            .NotNull()
            .GreaterThan(0);

        RuleFor(x => x.Limit)
            .NotNull()
            .InclusiveBetween(1, 50);
    }
}