using AnimeHub.Application.Dtos.Details;
using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/animes/details")]
[SwaggerTag("Detalhes unificados (local + providers externos).")]
public class AnimeDetailsController : ControllerBase
{
    private readonly IAnimeDetailsService _svc;
    public AnimeDetailsController(IAnimeDetailsService svc) => _svc = svc;

    [HttpGet]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Detalhe unificado de anime",
        Description = "Busca detalhe por fonte: local (id) ou externo (externalId). Ex.: source=AniList|Jikan|Kitsu."
    )]
    [ProducesResponseType(typeof(AnimeDetailsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Get(
        [FromQuery] AnimeDetailsQueryDto query,
        CancellationToken ct = default)
    {
        var details = await _svc.GetAsync(query.Source!, query.Id, query.ExternalId, ct);
        return details is null ? NotFound() : Ok(details);
    }
}