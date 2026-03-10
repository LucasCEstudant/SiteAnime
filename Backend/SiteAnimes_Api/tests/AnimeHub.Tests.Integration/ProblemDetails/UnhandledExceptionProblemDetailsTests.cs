using System.Net;
using System.Text.Json;
using FluentAssertions;

namespace AnimeHub.Tests.Integration.ProblemDetails;

public class UnhandledExceptionProblemDetailsTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public UnhandledExceptionProblemDetailsTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task UnhandledException_DeveRetornar500_ComoProblemDetails_ComTraceId()
    {
        // Esse endpoint existe só em Testing e sempre lança exception
        var resp = await _client.GetAsync("/api/__test/throw", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.InternalServerError);

        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        json.Should().NotBeNullOrWhiteSpace();

        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(500);
        doc.RootElement.GetProperty("title").GetString().Should().NotBeNullOrWhiteSpace();

        // CustomizeProblemDetails colocou traceId
        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
        doc.RootElement.TryGetProperty("path", out _).Should().BeTrue();
    }
}