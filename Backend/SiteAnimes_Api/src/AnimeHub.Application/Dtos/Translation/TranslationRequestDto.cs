namespace AnimeHub.Application.Dtos.Translation;

public record TranslationRequestDto(
    string Text,
    string TargetLang,
    string? SourceLang = null,
    string? Format = "text"
);
