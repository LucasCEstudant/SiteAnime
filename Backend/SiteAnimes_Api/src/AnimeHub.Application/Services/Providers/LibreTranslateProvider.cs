using System.Diagnostics;
using AnimeHub.Application.Dtos.Translation;
using AnimeHub.Application.Interfaces;
using AnimeHub.Infrastructure.External.Translation;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services.Providers;

public sealed class LibreTranslateProvider : ITranslationProvider
{
    public string ProviderName => "LibreTranslate";

    private readonly LibreTranslateClient _client;
    private readonly ILogger<LibreTranslateProvider> _logger;

    private static readonly Dictionary<string, string> LangMap = new(StringComparer.OrdinalIgnoreCase)
    {
        ["pt-BR"] = "pt",
        ["en-US"] = "en",
        ["es-ES"] = "es",
        ["zh-CN"] = "zh"
    };

    public LibreTranslateProvider(LibreTranslateClient client, ILogger<LibreTranslateProvider> logger)
    {
        _client = client;
        _logger = logger;
    }

    public async Task<TranslationResponseDto> TranslateAsync(
        string text, string sourceLang, string targetLang, string format, CancellationToken ct)
    {
        var source = NormalizeLang(sourceLang);
        var target = NormalizeLang(targetLang);

        _logger.LogDebug("LibreTranslate request: source={Source} target={Target} textLen={Len}",
            source, target, text.Length);

        var sw = Stopwatch.StartNew();

        // Respect cancellation and let caller's cancellation/timeout apply
        var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        try
        {
            var result = await _client.TranslateAsync(text, source, target, format ?? "text", linkedCts.Token);
            sw.Stop();

            _logger.LogDebug("LibreTranslate response in {Ms}ms detectedLang={Lang}",
                sw.ElapsedMilliseconds, result.DetectedLanguage);

            return new TranslationResponseDto(
                Text: result.TranslatedText,
                Provider: ProviderName,
                DetectedLanguage: result.DetectedLanguage,
                LatencyMs: sw.ElapsedMilliseconds,
                CacheHit: false
            );
        }
        finally
        {
            linkedCts.Dispose();
        }
    }

    private static string NormalizeLang(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang) || lang.Equals("auto", StringComparison.OrdinalIgnoreCase))
            return "auto";

        return LangMap.TryGetValue(lang, out var normalized) ? normalized : lang;
    }
}
