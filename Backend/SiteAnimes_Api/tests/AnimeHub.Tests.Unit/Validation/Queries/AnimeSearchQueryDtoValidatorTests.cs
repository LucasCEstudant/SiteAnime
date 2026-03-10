using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Validation.Queries;
using FluentAssertions;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Queries;

public class AnimeSearchQueryDtoValidatorTests
{
    private readonly AnimeSearchQueryDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoQVazio()
    {
        var dto = new AnimeSearchQueryDto("", 12, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Q);
    }

    [Fact]
    public void DeveFalhar_QuandoLimitNulo()
    {
        var dto = new AnimeSearchQueryDto("dra", null, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Limit);
    }

    [Fact]
    public void DevePassar_QuandoOk()
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DevePassar_QuandoYearValido()
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, 2023, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Theory]
    [InlineData(1899)]
    [InlineData(2101)]
    public void DeveFalhar_QuandoYearForaDoRange(int year)
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, year, null);
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Year);
    }

    [Fact]
    public void DevePassar_QuandoGenresValidos()
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, null, new List<string> { "Action", "Adventure" });
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DevePassar_QuandoGenresNulo()
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, null, null);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DeveFalhar_QuandoGenreVazio()
    {
        var dto = new AnimeSearchQueryDto("dra", 12, null, null, new List<string> { "" });
        var r = _sut.TestValidate(dto);
        r.IsValid.Should().BeFalse();
    }
}