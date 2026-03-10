using FluentAssertions;
using System.Net;

namespace AnimeHub.Tests.Integration.Health;

public sealed class HealthEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    public HealthEndpointsTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Live_DeveRetornar200()
    {
        var client = _factory.CreateClient();

        var resp = await client.GetAsync("/health/live", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Ready_DeveRetornar200()
    {
        var client = _factory.CreateClient();

        var resp = await client.GetAsync("/health/ready", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}