using FluentAssertions;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace AnimeHub.Tests.Integration.Auth
{
    public class AuthEndpointsTests : IClassFixture<ApiFactory>
    {
        private readonly HttpClient _client;

        public AuthEndpointsTests(ApiFactory factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task Login_DeveRetornarTokens_QuandoCredenciaisValidas()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "admin@animehub.local",
                password = "Admin@12345"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.OK);

            var payload = await response.Content.ReadFromJsonAsync<AuthResponseDto>(
                cancellationToken: TestContext.Current.CancellationToken);

            payload.Should().NotBeNull();
            payload!.AccessToken.Should().NotBeNullOrWhiteSpace();
            payload.RefreshToken.Should().NotBeNullOrWhiteSpace();
            payload.AccessTokenExpiresAtUtc.Should().BeAfter(DateTime.UtcNow);
            payload.RefreshTokenExpiresAtUtc.Should().BeAfter(DateTime.UtcNow);
        }

        // ---------------- NEGATIVOS (LOGIN) ----------------

        [Fact]
        public async Task Login_DeveRetornar401_QuandoSenhaInvalida()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "admin@animehub.local",
                password = "SENHA_ERRADA"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Login_DeveRetornar401_QuandoUsuarioNaoExiste()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "naoexiste@animehub.local",
                password = "qualquer"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Login_DeveRetornar400_QuandoBodyInvalido()
        {
            // sem password (ApiController geralmente devolve 400 por ModelState inválido)
            var response = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "admin@animehub.local"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        // ---------------- NEGATIVOS (REFRESH) ----------------

        [Fact]
        public async Task Refresh_DeveRetornar400_QuandoBodyInvalido()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/refresh", new
            {
                accessToken = "x"
                // faltou refreshToken
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task Refresh_DeveRetornar401_QuandoRefreshTokenInvalido()
        {
            var login = await LoginAsync();

            var response = await _client.PostAsJsonAsync("/api/auth/refresh", new
            {
                accessToken = login.AccessToken,
                refreshToken = "refresh_invalido"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Refresh_DeveRetornar401_QuandoAccessTokenInvalido()
        {
            var login = await LoginAsync();

            var response = await _client.PostAsJsonAsync("/api/auth/refresh", new
            {
                accessToken = "access_invalido",
                refreshToken = login.RefreshToken
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        // ---------------- NEGATIVOS (REVOKE) ----------------

        [Fact]
        public async Task Revoke_DeveRetornar401_SemToken()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                refreshToken = "qualquer"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Revoke_DeveRetornar401_TokenInvalido()
        {
            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", "token_invalido");

            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                refreshToken = "qualquer"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Revoke_DeveRetornar400_QuandoBodyInvalido()
        {
            await AuthorizeAsAdminAsync();

            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                // faltou refreshToken
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task Revoke_DeveRetornar404_QuandoRefreshTokenNaoExiste()
        {
            await AuthorizeAsAdminAsync();

            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                refreshToken = "nao-existe"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }

        // ---------------- helpers ----------------

        private async Task<AuthResponseDto> LoginAsync()
        {
            var response = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "admin@animehub.local",
                password = "Admin@12345"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.OK);

            var payload = await response.Content.ReadFromJsonAsync<AuthResponseDto>(
                cancellationToken: TestContext.Current.CancellationToken);

            payload.Should().NotBeNull();
            return payload!;
        }

        private async Task AuthorizeAsAdminAsync()
        {
            var auth = await LoginAsync();
            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        }

        private sealed class AuthResponseDto
        {
            [JsonPropertyName("accessToken")]
            public string AccessToken { get; set; } = string.Empty;

            [JsonPropertyName("accessTokenExpiresAtUtc")]
            public DateTime AccessTokenExpiresAtUtc { get; set; }

            [JsonPropertyName("refreshToken")]
            public string RefreshToken { get; set; } = string.Empty;

            [JsonPropertyName("refreshTokenExpiresAtUtc")]
            public DateTime RefreshTokenExpiresAtUtc { get; set; }
        }
    }
}