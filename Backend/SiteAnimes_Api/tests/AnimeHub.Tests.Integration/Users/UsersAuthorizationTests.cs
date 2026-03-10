using AnimeHub.Application.Dtos.Users;
using FluentAssertions;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace AnimeHub.Tests.Integration.Users;

public sealed class UsersAuthorizationTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;

    public UsersAuthorizationTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task UsuarioComum_NaoPode_AcessarEndpointsDeUsers_AdminOnly()
    {
        var client = _factory.CreateClient();

        // Admin cria um usuário comum
        var admin = await _factory.AuthenticateAdminAsync(client, TestContext.Current.CancellationToken);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);

        var email = $"user_{Guid.NewGuid():N}@animehub.local";
        var pass = "User@12345";

        var create = new UserCreateDto(email, pass, "User");
        var createResp = await client.PostAsJsonAsync("/api/users", create, TestContext.Current.CancellationToken);
        createResp.StatusCode.Should().Be(HttpStatusCode.Created);

        // Login como usuário comum
        client.DefaultRequestHeaders.Authorization = null;
        var loginResp = await client.PostAsJsonAsync("/api/auth/login", new { email, password = pass }, TestContext.Current.CancellationToken);
        loginResp.StatusCode.Should().Be(HttpStatusCode.OK);

        var json = await loginResp.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(cancellationToken: TestContext.Current.CancellationToken);
        var accessToken = json.GetProperty("accessToken").GetString();

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        // Deve dar 403 (autenticado, porém sem role Admin)
        var forbidden = await client.GetAsync("/api/users", TestContext.Current.CancellationToken);
        forbidden.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}