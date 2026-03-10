using System.ComponentModel.DataAnnotations;

namespace AnimeHub.Api.Options;

public sealed class TranslationOptions
{
    public const string SectionName = "Translation";

    [Required] public string BaseUrl { get; init; } = "http://localhost:5000";
    [Range(1, 44640)] public int CacheTtlMinutes { get; init; } = 1440;
    [Range(1, 300)] public int TimeoutSeconds { get; init; } = 60;
    public string[] SupportedLanguages { get; init; } = ["pt-BR", "en-US", "es-ES", "zh-CN"];
    public bool AllowPublicFallback { get; init; } = false;
    public string? FallbackBaseUrl { get; init; }
}
