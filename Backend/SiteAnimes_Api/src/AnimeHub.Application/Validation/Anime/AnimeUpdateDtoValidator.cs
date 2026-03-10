using AnimeHub.Application.Dtos.Anime;
using FluentValidation;

namespace AnimeHub.Application.Validation.Anime;

public sealed class AnimeUpdateDtoValidator : AbstractValidator<AnimeUpdateDto>
{
    public AnimeUpdateDtoValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty()
            .MaximumLength(200);

        RuleFor(x => x.Synopsis)
            .MaximumLength(4000)
            .When(x => !string.IsNullOrWhiteSpace(x.Synopsis));

        RuleFor(x => x.Year)
            .InclusiveBetween(1900, DateTime.UtcNow.Year + 1)
            .When(x => x.Year.HasValue);

        RuleFor(x => x.Score)
            .InclusiveBetween(0m, 10m)
            .When(x => x.Score.HasValue);

        RuleFor(x => x.CoverUrl)
            .Must(BeValidAbsoluteUrl)
            .When(x => !string.IsNullOrWhiteSpace(x.CoverUrl))
            .WithMessage("CoverUrl deve ser uma URL absoluta válida.");
    }

    private static bool BeValidAbsoluteUrl(string? url)
        => Uri.TryCreate(url, UriKind.Absolute, out _);
}