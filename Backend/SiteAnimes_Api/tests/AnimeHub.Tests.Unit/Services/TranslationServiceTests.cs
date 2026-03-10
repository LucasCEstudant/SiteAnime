using AnimeHub.Application.Dtos.Translation;
using AnimeHub.Application.Interfaces;
using AnimeHub.Application.Services;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Moq;

namespace AnimeHub.Tests.Unit.Services;

public class TranslationServiceTests
{
    private readonly Mock<ITranslationProvider> _providerMock = new();
    private readonly IMemoryCache _cache = new MemoryCache(new MemoryCacheOptions());
    private readonly Mock<ILogger<TranslationService>> _loggerMock = new();

    private TranslationService CreateSut(TimeSpan? ttl = null) =>
        new(_providerMock.Object, _cache, _loggerMock.Object, ttl ?? TimeSpan.FromMinutes(5));

    [Fact]
    public async Task TranslateAsync_DeveChamarProvider_QuandoCacheMiss()
    {
        var expected = new TranslationResponseDto("Olá", "LibreTranslate", "en", 100, false);
        _providerMock
            .Setup(p => p.TranslateAsync("Hello", "auto", "pt-BR", "text", It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var sut = CreateSut();
        var request = new TranslationRequestDto("Hello", "pt-BR");

        var result = await sut.TranslateAsync(request, CancellationToken.None);

        Assert.Equal("Olá", result.Text);
        Assert.Equal("LibreTranslate", result.Provider);
        Assert.False(result.CacheHit);
        _providerMock.Verify(p => p.TranslateAsync("Hello", "auto", "pt-BR", "text", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task TranslateAsync_DeveRetornarCache_QuandoCacheHit()
    {
        var expected = new TranslationResponseDto("Olá", "LibreTranslate", "en", 100, false);
        _providerMock
            .Setup(p => p.TranslateAsync("Hello", "auto", "pt-BR", "text", It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var sut = CreateSut();
        var request = new TranslationRequestDto("Hello", "pt-BR");

        // Primeiro call — cache miss
        var first = await sut.TranslateAsync(request, CancellationToken.None);
        Assert.False(first.CacheHit);

        // Segundo call — cache hit
        var second = await sut.TranslateAsync(request, CancellationToken.None);
        Assert.True(second.CacheHit);
        Assert.Equal(0, second.LatencyMs);

        // Provider chamado apenas 1 vez
        _providerMock.Verify(p => p.TranslateAsync("Hello", "auto", "pt-BR", "text", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task TranslateAsync_DeveUsarSourceLang_QuandoInformado()
    {
        var expected = new TranslationResponseDto("Hello", "LibreTranslate", null, 50, false);
        _providerMock
            .Setup(p => p.TranslateAsync("Olá", "pt-BR", "en-US", "text", It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var sut = CreateSut();
        var request = new TranslationRequestDto("Olá", "en-US", SourceLang: "pt-BR");

        var result = await sut.TranslateAsync(request, CancellationToken.None);

        Assert.Equal("Hello", result.Text);
        _providerMock.Verify(p => p.TranslateAsync("Olá", "pt-BR", "en-US", "text", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task TranslateAsync_DeveUsarAutoDetect_QuandoSourceLangNulo()
    {
        var expected = new TranslationResponseDto("Hola", "LibreTranslate", "en", 80, false);
        _providerMock
            .Setup(p => p.TranslateAsync("Hello", "auto", "es-ES", "text", It.IsAny<CancellationToken>()))
            .ReturnsAsync(expected);

        var sut = CreateSut();
        var request = new TranslationRequestDto("Hello", "es-ES");

        var result = await sut.TranslateAsync(request, CancellationToken.None);

        Assert.Equal("Hola", result.Text);
        Assert.Equal("en", result.DetectedLanguage);
    }
}
