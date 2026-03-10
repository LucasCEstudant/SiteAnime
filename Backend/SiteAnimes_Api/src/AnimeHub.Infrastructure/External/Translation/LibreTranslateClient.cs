using System.Net.Http.Json;
using System.Text.Json;

namespace AnimeHub.Infrastructure.External.Translation;

public sealed class LibreTranslateClient
{
    private readonly HttpClient _http;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public LibreTranslateClient(HttpClient http) => _http = http;

    public async Task<LibreTranslateResult> TranslateAsync(
        string text, string source, string target, string format, CancellationToken ct)
    {
        var payload = new LibreTranslateRequest
        {
            Q = text,
            Source = source,
            Target = target,
            Format = format
        };

        using var response = await _http.PostAsJsonAsync("/translate", payload, ct);

        if (!response.IsSuccessStatusCode)
        {
            // Try to include provider error in the exception message to aid debugging
            var body = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
            var msg = string.IsNullOrWhiteSpace(body)
                ? $"LibreTranslate responded with {(int)response.StatusCode} ({response.ReasonPhrase})."
                : body;

            throw new HttpRequestException(msg);
        }

        var result = await response.Content.ReadFromJsonAsync<LibreTranslateResponse>(JsonOptions, ct);

        if (result is null)
            throw new InvalidOperationException("LibreTranslate returned null response.");

        return new LibreTranslateResult(
            TranslatedText: result.TranslatedText,
            DetectedLanguage: result.DetectedLanguage?.Language
        );
    }
}

public record LibreTranslateResult(string TranslatedText, string? DetectedLanguage);
