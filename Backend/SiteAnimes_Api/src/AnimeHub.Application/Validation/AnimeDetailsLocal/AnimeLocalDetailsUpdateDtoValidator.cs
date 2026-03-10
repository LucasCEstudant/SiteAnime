using AnimeHub.Application.Dtos.AnimeDetailsLocal;
using FluentValidation;

namespace AnimeHub.Application.Validation.AnimeDetailsLocal;

public sealed class AnimeLocalDetailsUpdateDtoValidator : AbstractValidator<AnimeLocalDetailsUpdateDto>
{
    public AnimeLocalDetailsUpdateDtoValidator()
    {
        RuleFor(x => x.EpisodeCount)
            .InclusiveBetween(0, 5000)
            .When(x => x.EpisodeCount.HasValue);

        RuleFor(x => x.EpisodeLengthMinutes)
            .InclusiveBetween(1, 300)
            .When(x => x.EpisodeLengthMinutes.HasValue);

        RuleForEach(x => x.ExternalLinks)
            .SetValidator(new AnimeLocalExternalLinkDtoValidator())
            .When(x => x.ExternalLinks is not null);

        RuleForEach(x => x.StreamingEpisodes)
            .SetValidator(new AnimeLocalStreamingEpisodeDtoValidator())
            .When(x => x.StreamingEpisodes is not null);
    }

    private sealed class AnimeLocalExternalLinkDtoValidator : AbstractValidator<AnimeLocalExternalLinkDto>
    {
        public AnimeLocalExternalLinkDtoValidator()
        {
            RuleFor(x => x.Site)
                .NotEmpty()
                .MaximumLength(100);

            RuleFor(x => x.Url)
                .NotEmpty()
                .MaximumLength(2000)
                .Must(BeValidAbsoluteUrl)
                .WithMessage("Url deve ser uma URL absoluta válida.");
        }
    }

    private sealed class AnimeLocalStreamingEpisodeDtoValidator : AbstractValidator<AnimeLocalStreamingEpisodeDto>
    {
        public AnimeLocalStreamingEpisodeDtoValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty()
                .MaximumLength(200);

            RuleFor(x => x.Url)
                .NotEmpty()
                .MaximumLength(2000)
                .Must(BeValidAbsoluteUrl)
                .WithMessage("Url deve ser uma URL absoluta válida.");

            RuleFor(x => x.Site)
                .MaximumLength(100)
                .When(x => !string.IsNullOrWhiteSpace(x.Site));
        }
    }

    private static bool BeValidAbsoluteUrl(string? url)
        => Uri.TryCreate(url, UriKind.Absolute, out _);
}