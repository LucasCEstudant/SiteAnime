using AnimeHub.Application.Dtos.UserAnimes;
using FluentValidation;

namespace AnimeHub.Application.Validation.UserAnimes;

public sealed class UserAnimeCreateDtoValidator : AbstractValidator<UserAnimeCreateDto>
{
    private static readonly string[] AllowedStatuses =
        ["plan-to-watch", "watching", "completed", "dropped"];

    public UserAnimeCreateDtoValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty()
            .MaximumLength(250);

        RuleFor(x => x.ExternalId)
            .MaximumLength(100);

        RuleFor(x => x.ExternalProvider)
            .MaximumLength(50);

        RuleFor(x => x.CoverUrl)
            .MaximumLength(500);

        RuleFor(x => x.Status)
            .Must(s => s is null || AllowedStatuses.Contains(s))
            .WithMessage($"Status must be one of: {string.Join(", ", AllowedStatuses)}");

        RuleFor(x => x.Score)
            .InclusiveBetween(1m, 10m)
            .When(x => x.Score.HasValue);

        RuleFor(x => x.EpisodesWatched)
            .GreaterThanOrEqualTo(0)
            .When(x => x.EpisodesWatched.HasValue);

        RuleFor(x => x.Notes)
            .MaximumLength(2000);
    }
}
