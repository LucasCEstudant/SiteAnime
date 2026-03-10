using FluentAssertions;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace AnimeHub.Tests.Integration.ProblemDetails;

public class ProblemDetailsFormatTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public ProblemDetailsFormatTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task MissingQueryParam_DeveRetornar400_ProblemDetails_ComErroDoCampo()
    {
        var req = new HttpRequestMessage(HttpMethod.Get, "/api/animes/filters/genre?limit=12");
        req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/problem+json"));

        var resp = await _client.SendAsync(req, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        using var doc = JsonDocument.Parse(json);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.GetProperty("title").GetString().Should().NotBeNullOrWhiteSpace();

        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();
        errors.ValueKind.Should().Be(JsonValueKind.Object);

        // Pode vir de ModelBinding (genre) ou FluentValidation (Genre)
        (errors.TryGetProperty("Genre", out _) || errors.TryGetProperty("genre", out _))
            .Should().BeTrue();

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    [Fact]
    public async Task FluentValidation_BodyInvalido_DeveRetornar400_ProblemDetailsPadrao()
    {
        // Login é um endpoint fácil para disparar validação do body (DTO inválido)
        var req = new HttpRequestMessage(HttpMethod.Post, "/api/auth/login");
        req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/problem+json"));
        req.Content = JsonContent.Create(new
        {
            email = "",     // inválido
            password = ""   // inválido
        });

        var resp = await _client.SendAsync(req, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var doc = await ReadProblemDetailsAsync(resp);

        doc.RootElement.GetProperty("status").GetInt32().Should().Be(400);
        doc.RootElement.GetProperty("title").GetString().Should().Be("Validation failed");

        doc.RootElement.TryGetProperty("errors", out var errors).Should().BeTrue();
        errors.ValueKind.Should().Be(JsonValueKind.Object);

        // No FluentValidation, suas propriedades são "Email" e "Password" (conforme validator)
        errors.TryGetProperty("Email", out _).Should().BeTrue();
        errors.TryGetProperty("Password", out _).Should().BeTrue();

        doc.RootElement.TryGetProperty("traceId", out _).Should().BeTrue();
    }

    private static async Task<JsonDocument> ReadProblemDetailsAsync(HttpResponseMessage resp)
    {
        resp.Content.Headers.ContentType.Should().NotBeNull();
        resp.Content.Headers.ContentType!.MediaType.Should().Be("application/problem+json");

        var json = await resp.Content.ReadAsStringAsync();
        json.Should().NotBeNullOrWhiteSpace();

        return JsonDocument.Parse(json);
    }
}