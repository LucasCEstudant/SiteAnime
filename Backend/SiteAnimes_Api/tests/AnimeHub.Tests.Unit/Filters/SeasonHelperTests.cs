
using AnimeHub.Application.Helpers;
using FluentAssertions;

namespace AnimeHub.Tests.Unit.Filters;

public sealed class SeasonHelperTests
{
    [Fact]
    public void GetCurrentSeasonUtc_DeveRetornarSeasonValida_E_AnoValido()
    {
        var (season, year) = SeasonHelper.GetCurrentSeasonUtc();

        season.Should().NotBeNullOrWhiteSpace();
        season.Should().BeOneOf("WINTER", "SPRING", "SUMMER", "FALL");
        year.Should().BeGreaterThanOrEqualTo(2000);
        year.Should().BeLessThanOrEqualTo(DateTime.UtcNow.Year + 1);
    }
}