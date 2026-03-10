using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Validation.UserAnimes;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.UserAnimes;

public class UserAnimeCreateDtoValidatorDecimalsTests
{
    private readonly UserAnimeCreateDtoValidator _sut = new();

    [Fact]
    public void DevePassar_QuandoScoreDecimalValido()
    {
        var dto = new UserAnimeCreateDto(null, null, null, "Titulo", null, null, "completed", 8.58m, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveValidationErrorFor(x => x.Score);
    }

    [Fact]
    public void DeveFalhar_QuandoScoreMenorQueUm()
    {
        var dto = new UserAnimeCreateDto(null, null, null, "Titulo", null, null, "completed", 0.5m, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Score);
    }
}
