using AnimeHub.Application.Dtos.Filters;
using FluentAssertions;

namespace AnimeHub.Tests.Unit.Filters;

public sealed class FiltersCursorCodecTests
{
    [Fact]
    public void EncodeDecode_RoundTrip_DevePreservarCampos()
    {
        var cur = new FiltersCursor
        {
            LocalLastTitle = "Ano 2019",
            LocalLastId = 99,
            AniListPage = 4,
            KitsuOffset = 40,
            JikanPage = 3
        };

        var encoded = FiltersCursorCodec.Encode(cur);
        encoded.Should().NotBeNullOrWhiteSpace();

        var decoded = FiltersCursorCodec.DecodeOrNew(encoded);

        decoded.LocalLastTitle.Should().Be("Ano 2019");
        decoded.LocalLastId.Should().Be(99);
        decoded.AniListPage.Should().Be(4);
        decoded.KitsuOffset.Should().Be(40);
        decoded.JikanPage.Should().Be(3);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("lixo")]
    public void DecodeOrNew_Invalido_DeveRetornarDefault(string? cursor)
    {
        var decoded = FiltersCursorCodec.DecodeOrNew(cursor);

        decoded.Should().NotBeNull();
        decoded.LocalLastTitle.Should().BeNull();
        decoded.LocalLastId.Should().BeNull();
        decoded.AniListPage.Should().BeNull();
        decoded.KitsuOffset.Should().BeNull();
        decoded.JikanPage.Should().BeNull();
    }
}