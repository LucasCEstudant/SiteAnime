using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/meta/anilist")]
[AllowAnonymous]
[SwaggerTag("Metadados AniList (listas auxiliares para o front)")]
public sealed class AniListMetaController : ControllerBase
{
    private readonly IAniListMetaService _svc;
    public AniListMetaController(IAniListMetaService svc) => _svc = svc;

    [HttpGet("genres")]
    [SwaggerOperation(
        Summary = "Lista oficial de gêneros disponíveis no AniList",
        Description = "Retorna a GenreCollection do AniList (cacheada)."
    )]
    public async Task<IActionResult> GetGenres(CancellationToken ct)
        => Ok(await _svc.ListAllAvailableGenresAsync(ct));
}