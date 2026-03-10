using AnimeHub.Application.Dtos.HomeBanners;
using FluentValidation;

namespace AnimeHub.Application.Validation.HomeBanners;

public sealed class HomeBannerUpdateDtoValidator : AbstractValidator<HomeBannerUpdateDto>
{
    public HomeBannerUpdateDtoValidator()
    {
        RuleFor(x => x)
            .Must(x => x.AnimeId.HasValue || !string.IsNullOrWhiteSpace(x.ExternalId))
            .WithMessage("Either AnimeId or ExternalId must be provided.");

        RuleFor(x => x)
            .Must(x => !(x.AnimeId.HasValue && !string.IsNullOrWhiteSpace(x.ExternalId)))
            .WithMessage("Cannot set both AnimeId and ExternalId.");

        RuleFor(x => x.ExternalProvider)
            .NotEmpty()
            .When(x => !string.IsNullOrWhiteSpace(x.ExternalId))
            .WithMessage("ExternalProvider is required when ExternalId is provided.");

        RuleFor(x => x.ExternalId)
            .MaximumLength(100);

        RuleFor(x => x.ExternalProvider)
            .MaximumLength(50);
    }
}
