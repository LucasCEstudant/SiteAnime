using System.Net;
using System.Net.Http.Json;
using FluentAssertions;

namespace AnimeHub.Tests.Integration.Meta;

public class AniListMetaEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public AniListMetaEndpointsTests(ApiFactory factory) => _client = factory.CreateClient();

    [Fact]
    public async Task Genres_DeveRetornarLista()
    {
        var resp = await _client.GetAsync("/api/meta/anilist/genres", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        var genres = await resp.Content.ReadFromJsonAsync<List<string>>(cancellationToken: TestContext.Current.CancellationToken);
        genres.Should().NotBeNull();
        genres!.Should().Contain("Action");
    }
}