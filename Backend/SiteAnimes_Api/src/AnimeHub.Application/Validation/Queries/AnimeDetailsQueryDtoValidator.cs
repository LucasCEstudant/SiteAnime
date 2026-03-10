using AnimeHub.Application.Dtos.Queries;
using FluentValidation;

namespace AnimeHub.Application.Validation.Queries;

public sealed class AnimeDetailsQueryDtoValidator : AbstractValidator<AnimeDetailsQueryDto>
{
    private static readonly HashSet<string> AllowedSources =
        new(StringComparer.OrdinalIgnoreCase) { "local", "AniList", "Jikan", "Kitsu" };

    public AnimeDetailsQueryDtoValidator()
    {
        RuleFor(x => x.Source)
            .NotEmpty()
            .Must(s => s is not null && AllowedSources.Contains(s))
            .WithMessage("Source inválido. Use: local, AniList, Jikan, Kitsu.");

        When(x => x.Source != null && x.Source.Equals("local", StringComparison.OrdinalIgnoreCase), () =>
        {
            RuleFor(x => x.Id)
                .NotNull()
                .GreaterThan(0);

            RuleFor(x => x.ExternalId)
                .Must(string.IsNullOrWhiteSpace)
                .WithMessage("ExternalId não deve ser informado quando source=local.");
        });

        When(x => x.Source != null && !x.Source.Equals("local", StringComparison.OrdinalIgnoreCase), () =>
        {
            RuleFor(x => x.ExternalId)
                .NotEmpty()
                .MaximumLength(100);

            RuleFor(x => x.Id)
                .Must(id => id is null)
                .WithMessage("Id não deve ser informado quando source é externo.");
        });
    }
}