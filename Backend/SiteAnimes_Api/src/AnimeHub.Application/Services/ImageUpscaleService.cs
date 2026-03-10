using System.Net.Http.Headers;
using AnimeHub.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class ImageUpscaleService : IImageUpscaleService
{
    private readonly HttpClient _httpClient;
    private readonly HttpClient _upscaleClient;
    private readonly ILogger<ImageUpscaleService> _logger;
    private readonly string _serviceUrl;
    private readonly int _timeoutSeconds;
    private readonly long _maxFileBytes;
    private readonly HashSet<string> _allowedHosts;

    public ImageUpscaleService(
        HttpClient httpClient,
        HttpClient upscaleClient,
        ILogger<ImageUpscaleService> logger,
        string serviceUrl,
        int timeoutSeconds,
        int maxFileSizeMb,
        string[] allowedHosts)
    {
        _httpClient = httpClient;
        _upscaleClient = upscaleClient;
        _logger = logger;
        _serviceUrl = serviceUrl.TrimEnd('/');
        _timeoutSeconds = timeoutSeconds;
        _maxFileBytes = maxFileSizeMb * 1024L * 1024L;
        _allowedHosts = new HashSet<string>(allowedHosts, StringComparer.OrdinalIgnoreCase);
    }

    public async Task<ImageUpscaleResult> UpscaleAsync(string imageUrl, CancellationToken ct)
    {
        if (!Uri.TryCreate(imageUrl, UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
        {
            throw new ArgumentException("URL inválida.");
        }

        // If AllowedHosts is empty, allow any host. Otherwise enforce the allow-list.
        if (_allowedHosts.Count > 0 && !_allowedHosts.Contains(uri.Host))
            throw new ArgumentException($"Host '{uri.Host}' não é permitido.");

        var id = Guid.NewGuid().ToString("N")[..12];

        // 1. Download image from CDN
        using var downloadResponse = await _httpClient.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, ct);

        if (!downloadResponse.IsSuccessStatusCode)
            throw new InvalidOperationException($"CDN retornou status {(int)downloadResponse.StatusCode}.");

        if (downloadResponse.Content.Headers.ContentLength > _maxFileBytes)
            throw new InvalidOperationException($"Imagem excede o limite de {_maxFileBytes / (1024 * 1024)} MB.");

        var imageBytes = await downloadResponse.Content.ReadAsByteArrayAsync(ct);

        if (imageBytes.Length > _maxFileBytes)
            throw new InvalidOperationException($"Imagem excede o limite de {_maxFileBytes / (1024 * 1024)} MB.");

        _logger.LogDebug("Image downloaded for upscale. Size={Size} bytes, Id={Id}", imageBytes.Length, id);

        // 2. Send image to Real-ESRGAN microservice via HTTP
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        cts.CancelAfter(TimeSpan.FromSeconds(_timeoutSeconds));

        using var form = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(imageBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        form.Add(fileContent, "file", $"input_{id}.png");
        form.Add(new StringContent("4"), "scale");

        _logger.LogDebug("Sending upscale request to {Url}. Id={Id}", _serviceUrl, id);

        HttpResponseMessage upscaleResponse;
        try
        {
            upscaleResponse = await _upscaleClient.PostAsync($"{_serviceUrl}/upscale", form, cts.Token);
        }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested)
        {
            throw new TimeoutException($"Real-ESRGAN service did not respond within {_timeoutSeconds}s.");
        }

        if (!upscaleResponse.IsSuccessStatusCode)
        {
            var errorBody = await upscaleResponse.Content.ReadAsStringAsync(cts.Token);
            _logger.LogError("Real-ESRGAN service error. Status={Status} Body={Body} Id={Id}",
                (int)upscaleResponse.StatusCode, errorBody, id);
            throw new InvalidOperationException($"Real-ESRGAN service retornou status {(int)upscaleResponse.StatusCode}: {errorBody}");
        }

        var result = await upscaleResponse.Content.ReadAsByteArrayAsync(cts.Token);

        _logger.LogDebug("Upscale complete. OutputSize={Size} bytes, Id={Id}", result.Length, id);

        return new ImageUpscaleResult(result, "image/png");
    }
}
