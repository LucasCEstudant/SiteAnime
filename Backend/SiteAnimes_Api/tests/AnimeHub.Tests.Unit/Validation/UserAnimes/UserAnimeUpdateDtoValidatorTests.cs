using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Validation.UserAnimes;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.UserAnimes;

public class UserAnimeUpdateDtoValidatorTests
{
    private readonly UserAnimeUpdateDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoStatusInvalido()
    {
        var dto = new UserAnimeUpdateDto("On Going", null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Status);
    }

    [Fact]
    public void DeveFail_QuandoScoreForaDoRange()
    {
        var dto = new UserAnimeUpdateDto(null, 0, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Score);
    }

    [Fact]
    public void DevePassar_QuandoTudoNulo()
    {
        var dto = new UserAnimeUpdateDto(null, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}
