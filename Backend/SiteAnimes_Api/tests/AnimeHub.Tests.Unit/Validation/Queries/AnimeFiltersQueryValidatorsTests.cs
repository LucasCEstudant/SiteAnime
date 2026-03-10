using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Validation.Queries;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Queries;

public class AnimeFiltersQueryValidatorsTests
{
    [Fact]
    public void Genre_DeveFalhar_QuandoGenreVazio()
    {
        var sut = new AnimeFilterGenreQueryDtoValidator();
        var dto = new AnimeFilterGenreQueryDto("", 12, null);
        sut.TestValidate(dto).ShouldHaveValidationErrorFor(x => x.Genre);
    }

    [Fact]
    public void Year_DeveFalhar_QuandoYearNuloOuZero()
    {
        var sut = new AnimeFilterYearQueryDtoValidator();

        sut.TestValidate(new AnimeFilterYearQueryDto(null, 12, null))
            .ShouldHaveValidationErrorFor(x => x.Year);

        sut.TestValidate(new AnimeFilterYearQueryDto(0, 12, null))
            .ShouldHaveValidationErrorFor(x => x.Year);
    }

    [Fact]
    public void SeasonNow_DeveFalhar_QuandoLimitNulo()
    {
        var sut = new AnimeSeasonNowQueryDtoValidator();
        sut.TestValidate(new AnimeSeasonNowQueryDto(null, null))
            .ShouldHaveValidationErrorFor(x => x.Limit);
    }
}