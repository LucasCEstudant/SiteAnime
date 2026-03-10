using AnimeHub.Application.Dtos.Translation;

namespace AnimeHub.Application.Interfaces;

public interface ITranslationProvider
{
    string ProviderName { get; }

    Task<TranslationResponseDto> TranslateAsync(
        string text,
        string sourceLang,
        string targetLang,
        string format,
        CancellationToken ct);
}
