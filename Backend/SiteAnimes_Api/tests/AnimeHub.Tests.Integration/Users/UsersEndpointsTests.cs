using AnimeHub.Application.Dtos.Users;
using FluentAssertions;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace AnimeHub.Tests.Integration.Users;

public sealed class UsersEndpointsTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;

    public UsersEndpointsTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task Crud_Admin_DeveCriar_Listar_Obter_Atualizar_Deletar()
    {
        var client = _factory.CreateClient();

        var admin = await _factory.AuthenticateAdminAsync(client, TestContext.Current.CancellationToken);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);

        // CREATE
        var create = new UserCreateDto("user1@animehub.local", "User@12345", "User");

        var createResp = await client.PostAsJsonAsync("/api/users", create, TestContext.Current.CancellationToken);
        createResp.StatusCode.Should().Be(HttpStatusCode.Created);

        var createdJson = await createResp.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: TestContext.Current.CancellationToken);
        var createdId = createdJson.GetProperty("id").GetInt32();

        // GET ALL
        var allResp = await client.GetAsync("/api/users", TestContext.Current.CancellationToken);
        allResp.StatusCode.Should().Be(HttpStatusCode.OK);

        var allJson = await allResp.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: TestContext.Current.CancellationToken);
        allJson.ValueKind.Should().Be(JsonValueKind.Array);

        // GET BY ID
        var byIdResp = await client.GetAsync($"/api/users/{createdId}", TestContext.Current.CancellationToken);
        byIdResp.StatusCode.Should().Be(HttpStatusCode.OK);

        // UPDATE (role)
        var update = new UserUpdateDto(null, null, "Admin");
        var updResp = await client.PutAsJsonAsync($"/api/users/{createdId}", update, TestContext.Current.CancellationToken);
        updResp.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // DELETE
        var delResp = await client.DeleteAsync($"/api/users/{createdId}", TestContext.Current.CancellationToken);
        delResp.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // GET BY ID -> 404
        var byId404 = await client.GetAsync($"/api/users/{createdId}", TestContext.Current.CancellationToken);
        byId404.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task CreateUser_DeveRetornar400_QuandoRoleInvalida()
    {
        var client = _factory.CreateClient();

        var admin = await _factory.AuthenticateAdminAsync(client, TestContext.Current.CancellationToken);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", admin.AccessToken);

        var dto = new UserCreateDto("badrole@animehub.local", "User@12345", "SuperAdmin");
        var resp = await client.PostAsJsonAsync("/api/users", dto, TestContext.Current.CancellationToken);

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}