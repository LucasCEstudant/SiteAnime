using AnimeHub.Application.Dtos.Anime;
using AnimeHub.Application.Validation.Anime;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation;

public class AnimeCreateDtoValidatorTests
{
    private readonly AnimeCreateDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoTitleVazio()
    {
        var dto = new AnimeCreateDto("", null, null, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Title);
    }

    [Fact]
    public void DeveFalhar_QuandoScoreForaDoRange()
    {
        var dto = new AnimeCreateDto("Naruto", null, null, null, 11m, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Score);
    }

    [Fact]
    public void DeveFalhar_QuandoCoverUrlInvalida()
    {
        var dto = new AnimeCreateDto("Naruto", null, null, null, null, "x");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.CoverUrl);
    }

    [Fact]
    public void DevePassar_QuandoCamposValidos()
    {
        var dto = new AnimeCreateDto("Naruto", "desc", 2002, "Finished", 8.7m, "https://example.com/a.jpg");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}