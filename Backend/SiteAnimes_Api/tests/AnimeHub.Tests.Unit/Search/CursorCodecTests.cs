using AnimeHub.Application.Dtos.Search;
using FluentAssertions;

namespace AnimeHub.Tests.Unit.Search;

public sealed class CursorCodecTests
{
    [Fact]
    public void EncodeDecode_RoundTrip_DevePreservarCampos()
    {
        var cur = new UnifiedSearchCursor
        {
            LocalLastTitle = "Dragon",
            LocalLastId = 10,
            JikanPage = 2,
            AniListPage = 3,
            KitsuOffset = 24
        };

        var encoded = CursorCodec.Encode(cur);
        encoded.Should().NotBeNullOrWhiteSpace();

        var decoded = CursorCodec.DecodeOrNew(encoded);

        decoded.LocalLastTitle.Should().Be("Dragon");
        decoded.LocalLastId.Should().Be(10);
        decoded.JikanPage.Should().Be(2);
        decoded.AniListPage.Should().Be(3);
        decoded.KitsuOffset.Should().Be(24);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("lixo@@@")]
    public void DecodeOrNew_ComCursorInvalido_NaoDeveExplodir_DeveRetornarDefault(string? cursor)
    {
        var decoded = CursorCodec.DecodeOrNew(cursor);

        decoded.Should().NotBeNull();
        decoded.LocalLastTitle.Should().BeNull();
        decoded.LocalLastId.Should().BeNull();
        decoded.JikanPage.Should().BeNull();
        decoded.AniListPage.Should().BeNull();
        decoded.KitsuOffset.Should().BeNull();
    }
}