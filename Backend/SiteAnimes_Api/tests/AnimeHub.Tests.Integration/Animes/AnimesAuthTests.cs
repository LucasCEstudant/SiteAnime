using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using AnimeHub.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;

namespace AnimeHub.Tests.Integration.Animes
{
    public class AnimesAuthTests : IClassFixture<ApiFactory>
    {
        private readonly ApiFactory _factory;
        private readonly HttpClient _client;

        public AnimesAuthTests(ApiFactory factory)
        {
            _factory = factory;
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task PostAnime_DeveRetornar401_SemToken()
        {
            var response = await _client.PostAsJsonAsync("/api/animes", new
            {
                title = "One Piece",
                synopsis = "Piratas",
                year = 1999,
                score = 9.2m
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task PostAnime_DeveRetornar401_TokenInvalido()
        {
            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", "token_invalido");

            var response = await _client.PostAsJsonAsync("/api/animes", new
            {
                title = "One Piece",
                synopsis = "Piratas",
                year = 1999,
                score = 9.2m
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }

        [Fact]
        public async Task PostAnime_DeveRetornar403_ComUsuarioComum()
        {
            await EnsureCommonUserExistsAsync();
            await AuthorizeAsCommonAsync();

            var response = await _client.PostAsJsonAsync("/api/animes", new
            {
                title = "One Piece",
                synopsis = "Piratas",
                year = 1999,
                score = 9.2m
            }, TestContext.Current.CancellationToken);

            response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        }

        // ---------------- helpers ----------------

        private async Task EnsureCommonUserExistsAsync()
        {
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var email = "user@animehub.local";
            if (db.Users.Any(x => x.Email == email)) return;

            db.Users.Add(new AnimeHub.Domain.Entities.User
            {
                Email = email,
                PasswordHash = AnimeHub.Infrastructure.Auth.PasswordHasher.Hash("User@12345"),
                Role = "", // usuário comum sem role Admin
                CreatedAtUtc = DateTime.UtcNow
            });

            await db.SaveChangesAsync(TestContext.Current.CancellationToken);
        }

        private async Task AuthorizeAsCommonAsync()
        {
            var login = await _client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "user@animehub.local",
                password = "User@12345"
            }, TestContext.Current.CancellationToken);

            login.StatusCode.Should().Be(HttpStatusCode.OK);

            var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(
                cancellationToken: TestContext.Current.CancellationToken);

            auth.Should().NotBeNull();
            auth!.AccessToken.Should().NotBeNullOrWhiteSpace();

            _client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        }

        private sealed class AuthResponse
        {
            [JsonPropertyName("accessToken")]
            public string AccessToken { get; set; } = string.Empty;
        }
    }
}