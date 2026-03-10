using AnimeHub.Application.Dtos.AnimeDetailsLocal;
using AnimeHub.Application.Validation.AnimeDetailsLocal;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation;

public class AnimeLocalDetailsUpdateDtoValidatorTests
{
    private readonly AnimeLocalDetailsUpdateDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoEpisodeLengthMinutesForaDoRange()
    {
        var dto = new AnimeLocalDetailsUpdateDto(
            EpisodeCount: 10,
            EpisodeLengthMinutes: 999,
            ExternalLinks: null,
            StreamingEpisodes: null
        );

        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.EpisodeLengthMinutes);
    }

    [Fact]
    public void DeveFalhar_QuandoExternalLinkUrlInvalida()
    {
        var dto = new AnimeLocalDetailsUpdateDto(
            EpisodeCount: 10,
            EpisodeLengthMinutes: 24,
            ExternalLinks: new List<AnimeLocalExternalLinkDto>
            {
                new("Site", "x")
            },
            StreamingEpisodes: null
        );

        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor("ExternalLinks[0].Url");
    }

    [Fact]
    public void DeveFalhar_QuandoStreamingEpisodeTitleVazio()
    {
        var dto = new AnimeLocalDetailsUpdateDto(
            EpisodeCount: 10,
            EpisodeLengthMinutes: 24,
            ExternalLinks: null,
            StreamingEpisodes: new List<AnimeLocalStreamingEpisodeDto>
            {
                new("", "https://stream/1", "Provider")
            }
        );

        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor("StreamingEpisodes[0].Title");
    }

    [Fact]
    public void DevePassar_QuandoTudoOk()
    {
        var dto = new AnimeLocalDetailsUpdateDto(
            EpisodeCount: 12,
            EpisodeLengthMinutes: 24,
            ExternalLinks: new List<AnimeLocalExternalLinkDto>
            {
                new("Site", "https://example.com")
            },
            StreamingEpisodes: new List<AnimeLocalStreamingEpisodeDto>
            {
                new("Ep 1", "https://stream/1", "Provider")
            }
        );

        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}