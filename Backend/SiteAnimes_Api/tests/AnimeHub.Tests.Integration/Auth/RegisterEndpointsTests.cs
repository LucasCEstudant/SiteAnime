using FluentAssertions;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace AnimeHub.Tests.Integration.Auth;

public sealed class RegisterEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;

    public RegisterEndpointsTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Register_DeveRetornar201_E_PermitirLoginComNovoUsuario()
    {
        var client = _factory.CreateClient();

        var email = $"user_{Guid.NewGuid():N}@animehub.local";
        var password = "User@12345";

        // register (public)
        var registerResp = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password
        }, TestContext.Current.CancellationToken);

        registerResp.StatusCode.Should().Be(HttpStatusCode.Created);

        // login com o usuário criado
        var loginResp = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password
        }, TestContext.Current.CancellationToken);

        loginResp.StatusCode.Should().Be(HttpStatusCode.OK);

        var json = await loginResp.Content.ReadFromJsonAsync<JsonElement>(
            cancellationToken: TestContext.Current.CancellationToken);

        json.GetProperty("accessToken").GetString().Should().NotBeNullOrWhiteSpace();
        json.GetProperty("refreshToken").GetString().Should().NotBeNullOrWhiteSpace();
    }

    [Fact]
    public async Task Register_DeveRetornar409_QuandoEmailJaExiste()
    {
        var client = _factory.CreateClient();

        var email = $"dup_{Guid.NewGuid():N}@animehub.local";
        var password = "User@12345";

        // primeiro register -> 201
        var first = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password
        }, TestContext.Current.CancellationToken);

        first.StatusCode.Should().Be(HttpStatusCode.Created);

        // segundo register -> 409
        var second = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password
        }, TestContext.Current.CancellationToken);

        second.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task Register_DeveRetornar400_QuandoBodyInvalido()
    {
        var client = _factory.CreateClient();

        // email inválido + password curto -> FluentValidation -> 400
        var resp = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = "x",
            password = "123"
        }, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}