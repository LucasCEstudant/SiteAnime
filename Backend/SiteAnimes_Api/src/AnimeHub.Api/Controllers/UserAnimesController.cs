using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Interfaces;
using AnimeHub.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/users/me/animes")]
[Authorize]
[SwaggerTag("Lista pessoal de animes do usuário autenticado")]
public sealed class UserAnimesController : ControllerBase
{
    private readonly IUserAnimeService _svc;

    public UserAnimesController(IUserAnimeService svc) => _svc = svc;

    private int GetUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                  ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.Parse(sub!);
    }

    [HttpPost]
    [SwaggerOperation(Summary = "Adicionar anime à lista pessoal")]
    [ProducesResponseType(typeof(UserAnimeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Add([FromBody] UserAnimeCreateDto dto, CancellationToken ct)
    {
        try
        {
            var created = await _svc.AddAsync(GetUserId(), dto, ct);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }
        catch (DuplicateUserAnimeException ex)
        {
            return Conflict(new ProblemDetails
            {
                Title = "Anime já está na sua lista",
                Detail = ex.Message,
                Status = StatusCodes.Status409Conflict,
                Instance = HttpContext.Request.Path
            });
        }
    }

    [HttpGet]
    [SwaggerOperation(Summary = "Listar animes da lista pessoal (paginado)")]
    public async Task<IActionResult> List(
        [FromQuery] string? status,
        [FromQuery] int? year,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await _svc.ListAsync(GetUserId(), status, year, page, pageSize, ct);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [SwaggerOperation(Summary = "Obter item da lista por Id")]
    public async Task<IActionResult> GetById(int id, CancellationToken ct)
    {
        var item = await _svc.GetByIdAsync(id, GetUserId(), ct);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPut("{id:int}")]
    [SwaggerOperation(Summary = "Atualizar item da lista (status, score, episodesWatched, notes)")]
    public async Task<IActionResult> Update(int id, [FromBody] UserAnimeUpdateDto dto, CancellationToken ct)
    {
        var ok = await _svc.UpdateAsync(id, GetUserId(), dto, ct);
        return ok ? NoContent() : NotFound();
    }

    [HttpDelete("{id:int}")]
    [SwaggerOperation(Summary = "Remover anime da lista pessoal")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var ok = await _svc.DeleteAsync(id, GetUserId(), ct);
        return ok ? NoContent() : NotFound();
    }
}
