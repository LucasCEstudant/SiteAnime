using AnimeHub.Application.Dtos.Translation;

namespace AnimeHub.Application.Interfaces;

public interface ITranslationService
{
    Task<TranslationResponseDto> TranslateAsync(TranslationRequestDto request, CancellationToken ct);
}
