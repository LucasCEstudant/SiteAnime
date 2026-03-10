using FluentAssertions;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace AnimeHub.Tests.Integration.Swagger;

public sealed class SwaggerSecurityTests : IClassFixture<AnimeHub.Tests.Integration.ProductionApiFactory>
{
    private readonly AnimeHub.Tests.Integration.ProductionApiFactory _factory;
    public SwaggerSecurityTests(AnimeHub.Tests.Integration.ProductionApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Swagger_DeveRetornar401_SemToken_EmProduction()
    {
        var client = _factory.CreateClient();

        var resp = await client.GetAsync("/swagger/index.html", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Swagger_DeveRetornar200_ComAdmin_EmProduction()
    {
        var client = _factory.CreateClient();

        var admin = await _factory.AuthenticateAdminAsync(client, TestContext.Current.CancellationToken);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);

        var resp = await client.GetAsync("/swagger/index.html", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Swagger_DeveRetornar403_ComUsuarioNaoAdmin_EmProduction()
    {
        var client = _factory.CreateClient();

        // cria usuário comum via endpoint admin
        var admin = await _factory.AuthenticateAdminAsync(client, TestContext.Current.CancellationToken);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);

        var email = $"viewer_{Guid.NewGuid():N}@animehub.local";
        var pass = "User@12345";

        var createUser = await client.PostAsJsonAsync("/api/users", new
        {
            email,
            password = pass,
            role = "User"
        }, TestContext.Current.CancellationToken);

        createUser.EnsureSuccessStatusCode();

        // login como usuário comum
        client.DefaultRequestHeaders.Authorization = null;

        var loginResp = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = pass
        }, TestContext.Current.CancellationToken);

        loginResp.EnsureSuccessStatusCode();

        var json = await loginResp.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(cancellationToken: TestContext.Current.CancellationToken);
        var token = json.GetProperty("accessToken").GetString();

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var resp = await client.GetAsync("/swagger/index.html", TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}