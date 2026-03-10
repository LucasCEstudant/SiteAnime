using System.Net;
using System.Text.Json;
using FluentAssertions;

namespace AnimeHub.Tests.Integration.Queries;

public class QueryValidationTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;
    public QueryValidationTests(ApiFactory factory) => _client = factory.CreateClient();

    [Fact]
    public async Task Search_SemQ_DeveRetornar400_ProblemDetails()
    {
        var resp = await _client.GetAsync("/api/animes/search?limit=12", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        await AssertProblemDetailsHasError(resp, "Q");
    }

    [Fact]
    public async Task Details_SourceLocal_SemId_DeveRetornar400_ProblemDetails()
    {
        var resp = await _client.GetAsync("/api/animes/details?source=local", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        await AssertProblemDetailsHasError(resp, "Id");
    }

    [Fact]
    public async Task Filters_Genre_SemGenre_DeveRetornar400_ProblemDetails()
    {
        var resp = await _client.GetAsync("/api/animes/filters/genre?limit=12", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        await AssertProblemDetailsHasError(resp, "Genre");
    }

    [Fact]
    public async Task Filters_Year_SemYear_DeveRetornar400_ProblemDetails()
    {
        var resp = await _client.GetAsync("/api/animes/filters/year?limit=12", TestContext.Current.CancellationToken);
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        await AssertProblemDetailsHasError(resp, "Year");
    }

    private static async Task AssertProblemDetailsHasError(HttpResponseMessage resp, string key)
    {
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();
        errors.TryGetProperty(key, out _).Should().BeTrue();

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }
}