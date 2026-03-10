using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using FluentAssertions;

namespace AnimeHub.Tests.Integration.Auth
{
    public class RefreshTokenEndpointsTests : IClassFixture<ApiFactory>
    {
        private readonly HttpClient _client;

        public RefreshTokenEndpointsTests(ApiFactory factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task Refresh_DeveRetornarNovosTokens_QuandoRefreshValido()
        {
            var login = await LoginAsync();

            var response = await _client.PostAsJsonAsync(
                "/api/auth/refresh",
                new RefreshRequestDto { AccessToken = login.AccessToken, RefreshToken = login.RefreshToken },
                TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.OK);

            var refreshed = await response.Content.ReadFromJsonAsync<AuthResponseDto>(
                cancellationToken: TestContext.Current.CancellationToken);

            refreshed.Should().NotBeNull();
            refreshed!.AccessToken.Should().NotBeNullOrWhiteSpace();
            refreshed.RefreshToken.Should().NotBeNullOrWhiteSpace();

            // Deve mudar após refresh
            refreshed.AccessToken.Should().NotBe(login.AccessToken);
            refreshed.RefreshToken.Should().NotBe(login.RefreshToken);

            refreshed.AccessTokenExpiresAtUtc.Should().BeAfter(DateTime.UtcNow);
            refreshed.RefreshTokenExpiresAtUtc.Should().BeAfter(DateTime.UtcNow);
        }

        [Fact]
        public async Task Refresh_DeveRetornar401_QuandoReutilizarRefreshAntigo_RotacaoSingleUse()
        {
            var login = await LoginAsync();

            // primeiro refresh -> token rotaciona
            var first = await _client.PostAsJsonAsync(
                "/api/auth/refresh",
                new RefreshRequestDto { AccessToken = login.AccessToken, RefreshToken = login.RefreshToken },
                TestContext.Current.CancellationToken);

            first.StatusCode.Should().Be(HttpStatusCode.OK);

            var firstPayload = await first.Content.ReadFromJsonAsync<AuthResponseDto>(
                cancellationToken: TestContext.Current.CancellationToken);

            firstPayload.Should().NotBeNull();
            firstPayload!.RefreshToken.Should().NotBe(login.RefreshToken);

            // tenta usar o refresh antigo de novo
            var second = await _client.PostAsJsonAsync(
                "/api/auth/refresh",
                new RefreshRequestDto { AccessToken = login.AccessToken, RefreshToken = login.RefreshToken },
                TestContext.Current.CancellationToken);

            second.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Revoke_DeveInvalidarRefreshToken_E_AposIssoRefreshDeveFalhar()
        {
            var login = await LoginAsync();

            // revoke exige bearer
            using var revokeRequest = new HttpRequestMessage(HttpMethod.Post, "/api/auth/revoke")
            {
                Content = JsonContent.Create(new RevokeRequestDto { RefreshToken = login.RefreshToken })
            };
            revokeRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", login.AccessToken);

            var revokeResponse = await _client.SendAsync(revokeRequest, TestContext.Current.CancellationToken);
            revokeResponse.StatusCode.Should().Be(HttpStatusCode.OK);

            // refresh com token revogado deve falhar
            var refreshAfterRevoke = await _client.PostAsJsonAsync(
                "/api/auth/refresh",
                new RefreshRequestDto { AccessToken = login.AccessToken, RefreshToken = login.RefreshToken },
                TestContext.Current.CancellationToken);

            refreshAfterRevoke.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        // ---------------- NEGATIVOS (REFRESH) ----------------

        [Fact]
        public async Task Refresh_DeveRetornar400_QuandoBodyInvalido()
        {
            // faltando refreshToken
            var response = await _client.PostAsJsonAsync("/api/auth/refresh", new
            {
                accessToken = "x"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
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

        // ---------------- NEGATIVOS (REVOKE) ----------------

        [Fact]
        public async Task Revoke_DeveRetornar401_SemBearer()
        {
            // garante que não ficou auth de outro teste
            _client.DefaultRequestHeaders.Authorization = null;

            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                refreshToken = "qualquer"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task Revoke_DeveRetornar401_ComBearerInvalido()
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
            var login = await LoginAsync();
            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", login.AccessToken);

            // faltando refreshToken
            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new { }, TestContext.Current.CancellationToken);
            response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        }

        [Fact]
        public async Task Revoke_DeveRetornar404_QuandoRefreshTokenNaoExiste()
        {
            var login = await LoginAsync();
            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", login.AccessToken);

            var response = await _client.PostAsJsonAsync("/api/auth/revoke", new
            {
                refreshToken = "nao-existe"
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.NotFound);
        }

        [Fact]
        public async Task Revoke_MesmoRefreshToken_DuasVezes_DeveRetornar200_AmbasAsVezes_Idempotente()
        {
            // Arrange
            var login = await LoginAsync();

            // Revoke exige bearer
            using var revoke1 = new HttpRequestMessage(HttpMethod.Post, "/api/auth/revoke")
            {
                Content = JsonContent.Create(new RevokeRequestDto { RefreshToken = login.RefreshToken })
            };
            revoke1.Headers.Authorization = new AuthenticationHeaderValue("Bearer", login.AccessToken);

            using var revoke2 = new HttpRequestMessage(HttpMethod.Post, "/api/auth/revoke")
            {
                Content = JsonContent.Create(new RevokeRequestDto { RefreshToken = login.RefreshToken })
            };
            revoke2.Headers.Authorization = new AuthenticationHeaderValue("Bearer", login.AccessToken);

            // Act
            var resp1 = await _client.SendAsync(revoke1, TestContext.Current.CancellationToken);
            var resp2 = await _client.SendAsync(revoke2, TestContext.Current.CancellationToken);

            // Assert
            resp1.StatusCode.Should().Be(HttpStatusCode.OK);
            resp2.StatusCode.Should().Be(HttpStatusCode.OK);

            // E após revogar, refresh deve falhar (garantia)
            var refreshAfter = await _client.PostAsJsonAsync(
                "/api/auth/refresh",
                new RefreshRequestDto { AccessToken = login.AccessToken, RefreshToken = login.RefreshToken },
                TestContext.Current.CancellationToken);

            refreshAfter.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        // ---------- helpers ----------

        private async Task<AuthResponseDto> LoginAsync()
        {
            // garante que nenhum bearer antigo atrapalhe o login
            _client.DefaultRequestHeaders.Authorization = null;

            var response = await _client.PostAsJsonAsync(
                "/api/auth/login",
                new LoginRequestDto { Email = "admin@animehub.local", Password = "Admin@12345" },
                TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.OK);

            var payload = await response.Content.ReadFromJsonAsync<AuthResponseDto>(
                cancellationToken: TestContext.Current.CancellationToken);

            payload.Should().NotBeNull();
            payload!.AccessToken.Should().NotBeNullOrWhiteSpace();
            payload.RefreshToken.Should().NotBeNullOrWhiteSpace();

            return payload;
        }

        private sealed class LoginRequestDto
        {
            [JsonPropertyName("email")]
            public string Email { get; set; } = string.Empty;

            [JsonPropertyName("password")]
            public string Password { get; set; } = string.Empty;
        }

        private sealed class RefreshRequestDto
        {
            [JsonPropertyName("accessToken")]
            public string AccessToken { get; set; } = string.Empty;

            [JsonPropertyName("refreshToken")]
            public string RefreshToken { get; set; } = string.Empty;
        }

        private sealed class RevokeRequestDto
        {
            [JsonPropertyName("refreshToken")]
            public string RefreshToken { get; set; } = string.Empty;
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