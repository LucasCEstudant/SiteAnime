using AnimeHub.Application.Dtos.Anime;
using AnimeHub.Application.Validation.Anime;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation;

public class AnimeUpdateDtoValidatorTests
{
    private readonly AnimeUpdateDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoTitleVazio()
    {
        var dto = new AnimeUpdateDto("", null, null, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Title);
    }

    [Fact]
    public void DevePassar_QuandoCamposValidos()
    {
        var dto = new AnimeUpdateDto("Bleach", "desc", 2004, "Finished", 8.0m, "https://example.com/b.jpg");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}