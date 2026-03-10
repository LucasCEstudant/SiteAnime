using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Validation.UserAnimes;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.UserAnimes;

public class UserAnimeCreateDtoValidatorTests
{
    private readonly UserAnimeCreateDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoTitleVazio()
    {
        var dto = new UserAnimeCreateDto(null, null, null, string.Empty, null, null, null, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Title);
    }

    [Fact]
    public void DeveFalhar_QuandoStatusInvalido()
    {
        var dto = new UserAnimeCreateDto(null, null, null, "Titulo", null, null, "On Going", null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Status);
    }

    [Fact]
    public void DeveFalhar_QuandoScoreForaDoRange()
    {
        var dto = new UserAnimeCreateDto(null, null, null, "Titulo", null, null, "watching", 11, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Score);
    }

    [Fact]
    public void DevePassar_QuandoTudoValido()
    {
        var dto = new UserAnimeCreateDto(null, "ext", "Jikan", "Titulo", 2026, "https://img", "completed", 8, 2, "nota");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}
