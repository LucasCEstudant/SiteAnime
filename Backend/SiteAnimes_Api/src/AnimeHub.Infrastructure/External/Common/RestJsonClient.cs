using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace AnimeHub.Infrastructure.External.Common;

public sealed class RestJsonClient
{
    private readonly HttpClient _http;
    private readonly JsonSerializerOptions _json;

    public RestJsonClient(HttpClient http)
    {
        _http = http;
        _json = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };
    }

    public async Task<T?> GetAsync<T>(string relativeUrl, CancellationToken ct, bool treatNotFoundAsNull = false)
    {
        using var resp = await _http.GetAsync(relativeUrl, ct);

        if (treatNotFoundAsNull && resp.StatusCode == HttpStatusCode.NotFound)
            return default;

        // 204/empty também pode virar null sem quebrar
        if (resp.StatusCode == HttpStatusCode.NoContent)
            return default;

        resp.EnsureSuccessStatusCode();

        return await resp.Content.ReadFromJsonAsync<T>(_json, ct);
    }
}