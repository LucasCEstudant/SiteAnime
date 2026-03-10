using FluentAssertions;
using System.Net;
using System.Net.Http.Json;

namespace AnimeHub.Tests.Integration.RateLimit;

public sealed class AuthRateLimitTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;
    public AuthRateLimitTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Login_DeveRetornar429_QuandoExcederLimite()
    {
        var client = _factory.CreateClient();

        HttpResponseMessage? last = null;

        // ajuste conforme sua policy "auth-login" (ex: 10 por minuto)
        for (var i = 0; i < 11; i++)
        {
            last = await client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "admin@animehub.local",
                password = "Admin@12345"
            }, TestContext.Current.CancellationToken);
        }

        last!.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
    }
}