using AnimeHub.Application.Dtos.Queries;
using FluentValidation;

namespace AnimeHub.Application.Validation.Queries;

public sealed class AnimeFilterGenreQueryDtoValidator : AbstractValidator<AnimeFilterGenreQueryDto>
{
    public AnimeFilterGenreQueryDtoValidator()
    {
        RuleFor(x => x.Genre)
            .NotEmpty()
            .MaximumLength(50);

        RuleFor(x => x.Limit)
            .NotNull()
            .InclusiveBetween(1, 50);
    }
}