using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Validation.Queries;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Queries;

public class AnimeDetailsQueryDtoValidatorTests
{
    private readonly AnimeDetailsQueryDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoSourceVazio()
    {
        var dto = new AnimeDetailsQueryDto(null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Source);
    }

    [Fact]
    public void DeveFalhar_QuandoSourceLocal_SemId()
    {
        var dto = new AnimeDetailsQueryDto("local", null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Id);
    }

    [Fact]
    public void DeveFalhar_QuandoSourceExterno_SemExternalId()
    {
        var dto = new AnimeDetailsQueryDto("AniList", null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.ExternalId);
    }

    [Fact]
    public void DevePassar_QuandoLocal_ComId()
    {
        var dto = new AnimeDetailsQueryDto("local", 10, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DevePassar_QuandoExterno_ComExternalId()
    {
        var dto = new AnimeDetailsQueryDto("Jikan", null, "5114");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}