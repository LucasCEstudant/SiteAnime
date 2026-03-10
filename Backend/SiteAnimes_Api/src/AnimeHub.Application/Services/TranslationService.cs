using System.Security.Cryptography;
using System.Text;
using AnimeHub.Application.Dtos.Translation;
using AnimeHub.Application.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class TranslationService : ITranslationService
{
    private readonly ITranslationProvider _provider;
    private readonly IMemoryCache _cache;
    private readonly ILogger<TranslationService> _logger;
    private readonly TimeSpan _cacheTtl;

    public TranslationService(
        ITranslationProvider provider,
        IMemoryCache cache,
        ILogger<TranslationService> logger,
        TimeSpan cacheTtl)
    {
        _provider = provider;
        _cache = cache;
        _logger = logger;
        _cacheTtl = cacheTtl;
    }

    public async Task<TranslationResponseDto> TranslateAsync(TranslationRequestDto request, CancellationToken ct)
    {
        var sourceLang = string.IsNullOrWhiteSpace(request.SourceLang) ? "auto" : request.SourceLang;
        var format = string.IsNullOrWhiteSpace(request.Format) ? "text" : request.Format;
        var textHash = ComputeSha256(request.Text);

        var cacheKey = $"translation:{sourceLang}:{request.TargetLang}:{textHash}";

        if (_cache.TryGetValue(cacheKey, out TranslationResponseDto? cached) && cached is not null)
        {
            _logger.LogDebug("Translation cache hit for key {Key}", cacheKey);
            return cached with { CacheHit = true, LatencyMs = 0 };
        }

        _logger.LogDebug("Translation cache miss for key {Key}", cacheKey);

        var result = await _provider.TranslateAsync(request.Text, sourceLang, request.TargetLang, format, ct);

        _cache.Set(cacheKey, result, _cacheTtl);

        return result;
    }

    private static string ComputeSha256(string text)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(text));
        return Convert.ToHexStringLower(hash);
    }
}
