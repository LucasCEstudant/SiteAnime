using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Validation.UserAnimes;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.UserAnimes;

public class UserAnimeUpdateDtoValidatorDecimalsTests
{
    private readonly UserAnimeUpdateDtoValidator _sut = new();

    [Fact]
    public void DevePassar_QuandoScoreDecimalValido()
    {
        var dto = new UserAnimeUpdateDto("completed", 9.25m, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveValidationErrorFor(x => x.Score);
    }

    [Fact]
    public void DeveFalhar_QuandoScoreMaiorQueDez()
    {
        var dto = new UserAnimeUpdateDto(null, 10.5m, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Score);
    }
}
