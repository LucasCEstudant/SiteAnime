using AnimeHub.Application.Dtos.Translation;
using FluentValidation;

namespace AnimeHub.Application.Validation.Translation;

public sealed class TranslationRequestDtoValidator : AbstractValidator<TranslationRequestDto>
{
    private static readonly HashSet<string> SupportedLanguages = new(StringComparer.OrdinalIgnoreCase)
    {
        "pt-BR", "en-US", "es-ES", "zh-CN"
    };

    public TranslationRequestDtoValidator()
    {
        RuleFor(x => x.Text)
            .NotEmpty()
            .WithMessage("Text é obrigatório.")
            .MaximumLength(5000)
            .WithMessage("Text deve ter no máximo 5000 caracteres.");

        RuleFor(x => x.TargetLang)
            .NotEmpty()
            .WithMessage("TargetLang é obrigatório.")
            .Must(lang => SupportedLanguages.Contains(lang))
            .WithMessage("TargetLang não suportado. Idiomas suportados: pt-BR, en-US, es-ES, zh-CN.");

        RuleFor(x => x.SourceLang)
            .Must(lang => string.IsNullOrEmpty(lang) || SupportedLanguages.Contains(lang))
            .WithMessage("SourceLang não suportado. Idiomas suportados: pt-BR, en-US, es-ES, zh-CN.");

        RuleFor(x => x.Format)
            .Must(f => string.IsNullOrEmpty(f) || f == "text" || f == "html")
            .WithMessage("Format deve ser 'text' ou 'html'.");
    }
}
