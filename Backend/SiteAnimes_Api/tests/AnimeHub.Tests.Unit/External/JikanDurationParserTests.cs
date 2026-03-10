using AnimeHub.Application.Helpers;
using FluentAssertions;

namespace AnimeHub.Tests.Unit.External;

public sealed class JikanDurationParserTests
{
    [Theory]
    [InlineData("24 min per ep", 24)]
    [InlineData("9 min", 9)]
    [InlineData("24", 24)]
    [InlineData("unknown", null)]
    [InlineData("", null)]
    [InlineData(null, null)]
    public void ParseMinutes_DeveFuncionar(string? input, int? expected)
    {
        var result = JikanDurationParserHelper.ParseMinutes(input);
        result.Should().Be(expected);
    }
}
