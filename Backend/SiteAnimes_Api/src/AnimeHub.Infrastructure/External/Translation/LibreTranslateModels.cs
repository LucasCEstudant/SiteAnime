using System.Text.Json.Serialization;

namespace AnimeHub.Infrastructure.External.Translation;

internal sealed class LibreTranslateRequest
{
    [JsonPropertyName("q")]
    public string Q { get; init; } = "";

    [JsonPropertyName("source")]
    public string Source { get; init; } = "auto";

    [JsonPropertyName("target")]
    public string Target { get; init; } = "";

    [JsonPropertyName("format")]
    public string Format { get; init; } = "text";
}

internal sealed class LibreTranslateResponse
{
    [JsonPropertyName("translatedText")]
    public string TranslatedText { get; init; } = "";

    [JsonPropertyName("detectedLanguage")]
    public DetectedLanguageInfo? DetectedLanguage { get; init; }
}

internal sealed class DetectedLanguageInfo
{
    [JsonPropertyName("confidence")]
    public double Confidence { get; init; }

    [JsonPropertyName("language")]
    public string Language { get; init; } = "";
}
