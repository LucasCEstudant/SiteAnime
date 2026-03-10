using AnimeHub.Application.Dtos.Queries;
using FluentValidation;

namespace AnimeHub.Application.Validation.Queries;

public sealed class AnimeSearchQueryDtoValidator : AbstractValidator<AnimeSearchQueryDto>
{
    public AnimeSearchQueryDtoValidator()
    {
        RuleFor(x => x.Q)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.Limit)
            .NotNull()
            .InclusiveBetween(1, 50);

        // Cursor: opcional, sem validação aqui (codec já lida com inválido/novo)

        RuleFor(x => x.Year)
            .InclusiveBetween(1900, 2100)
            .When(x => x.Year.HasValue);

        RuleForEach(x => x.Genres)
            .NotEmpty()
            .MaximumLength(50)
            .When(x => x.Genres is { Count: > 0 });
    }
}