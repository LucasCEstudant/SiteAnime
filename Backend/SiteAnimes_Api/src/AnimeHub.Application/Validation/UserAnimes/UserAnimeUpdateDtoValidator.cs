using AnimeHub.Application.Dtos.UserAnimes;
using FluentValidation;

namespace AnimeHub.Application.Validation.UserAnimes;

public sealed class UserAnimeUpdateDtoValidator : AbstractValidator<UserAnimeUpdateDto>
{
    private static readonly string[] AllowedStatuses =
        ["plan-to-watch", "watching", "completed", "dropped"];

    public UserAnimeUpdateDtoValidator()
    {
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
