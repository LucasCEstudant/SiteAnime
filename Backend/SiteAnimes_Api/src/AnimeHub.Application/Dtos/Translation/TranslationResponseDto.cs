namespace AnimeHub.Application.Dtos.Translation;

public record TranslationResponseDto(
    string Text,
    string Provider,
    string? DetectedLanguage,
    long LatencyMs,
    bool CacheHit
);
