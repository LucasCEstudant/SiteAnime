using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using Microsoft.AspNetCore.RateLimiting;

namespace AnimeHub.Api.Controllers;

/// <summary>
/// Proxy de imagens — busca imagens de CDNs externos (AniList, MAL, Kitsu)
/// server-side, evitando bloqueios CORS no browser do usuário.
/// Usado pelo front apenas para as 2 imagens grandes (Hero + Featured).
/// </summary>
[ApiController]
[Route("api/image-proxy")]
[AllowAnonymous]
[EnableRateLimiting("image-proxy")]
[SwaggerTag("Proxy de imagens (contorna CORS de CDNs externos)")]
public sealed class ImageProxyController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;

    // NOTE: Host allow-list removed temporaly. Controller accepts any http/https URL. (SSRF risk).
    // Apenas CDNs de anime confiáveis
    //private static readonly HashSet<string> AllowedHosts =
    //[
    //    "s4.anilist.co",
    //    "s1.anilist.co",
    //    "s2.anilist.co",
    //    "s3.anilist.co",
    //    "img1.ak.crunchyroll.com",
    //    "cdn.myanimelist.net",
    //    "media.kitsu.app",
    //    "media.kitsu.io",
    //];

    public ImageProxyController(IHttpClientFactory factory)
        => _httpClientFactory = factory;

    [HttpGet]
    [SwaggerOperation(
        Summary = "Faz proxy de uma imagem de CDN externo",
        Description = "Aceita ?url= com URL de imagem de CDN de anime (AniList, MAL, Kitsu). " +
                      "Busca server-side e retorna os bytes, contornando CORS do browser."
    )]
    public async Task<IActionResult> Proxy(
        [FromQuery] string url,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(url)
            || !Uri.TryCreate(url, UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
        {
            return BadRequest("URL inválida.");
        }

        // No host allow-list: accept any http/https host. Caller must ensure URL is trusted.

        var http = _httpClientFactory.CreateClient("ImageProxy");

        try
        {
            using var response = await http.GetAsync(uri, HttpCompletionOption.ResponseHeadersRead, ct);

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, "CDN retornou erro.");

            var contentType = response.Content.Headers.ContentType?.ToString()
                              ?? "image/jpeg";

            // Cache agressivo — imagens de capa mudam raramente
            Response.Headers.CacheControl = "public, max-age=86400"; // 24h

            var bytes = await response.Content.ReadAsByteArrayAsync(ct);
            return File(bytes, contentType);
        }
        catch (TaskCanceledException)
        {
            return StatusCode(408, "Timeout ao buscar imagem.");
        }
        catch (Exception ex)
        {
            return StatusCode(502, $"Falha ao buscar imagem: {ex.Message}");
        }
    }
}
