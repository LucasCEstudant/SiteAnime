using AnimeHub.Application.Dtos.AnimeDetailsLocal;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/animes/{id:int}/details")]
[SwaggerTag("Detalhes locais do anime (Admin atualiza; público pode consultar).")]
public sealed class AnimeLocalDetailsController : ControllerBase
{
    private readonly IAnimeLocalDetailsService _svc;
    public AnimeLocalDetailsController(IAnimeLocalDetailsService svc) => _svc = svc;

    [HttpGet]
    [AllowAnonymous]
    [SwaggerOperation(Summary = "Consultar detalhes locais do anime", Description = "Retorna detalhes cadastrados no banco local para o anime.")]
    [ProducesResponseType(typeof(AnimeLocalDetailsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken ct)
    {
        var dto = await _svc.GetAsync(id, ct);
        return dto is null ? NotFound() : Ok(dto);
    }

    [HttpPut]
    [Authorize(Roles = "Admin")]
    [SwaggerOperation(Summary = "Atualizar detalhes locais do anime", Description = "Atualiza episódios/links/streamingEpisodes no banco local.")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] AnimeLocalDetailsUpdateDto dto, CancellationToken ct)
    {
        var ok = await _svc.UpdateAsync(id, dto, ct);
        return ok ? NoContent() : NotFound();
    }
}