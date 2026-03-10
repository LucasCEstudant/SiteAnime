using System.Net;
using System.Net.Http.Json;

namespace AnimeHub.Infrastructure.External.Common;

public sealed class GraphQlClient
{
    private readonly HttpClient _http;

    public GraphQlClient(HttpClient http) => _http = http;

    public async Task<TResponse?> PostAsync<TResponse>(string query, object variables, CancellationToken ct)
    {
        var req = new GraphQlRequest(query, variables);

        var resp = await _http.PostAsJsonAsync("", req, ct);

        // Se a API responder 404, tratamos como "não encontrado" para o caller decidir (ex.: Details -> NotFound).
        if (resp.StatusCode == HttpStatusCode.NotFound)
            return default;

        // Outros erros permanecem fail-fast (500/429 etc.) para você logar/monitorar.
        resp.EnsureSuccessStatusCode();

        return await resp.Content.ReadFromJsonAsync<TResponse>(cancellationToken: ct);
    }
}