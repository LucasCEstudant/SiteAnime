using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controller;

[ApiController]
[Route("api/animes")]
public class AnimeSearchController : ControllerBase
{
    private readonly IAnimeSearchService _search;

    public AnimeSearchController(IAnimeSearchService search)
    {
        _search = search;
    }

    [HttpGet("search")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Busca agregada com todos os provedores externos + o DB interno",
        Description = ""
    )]
    public async Task<IActionResult> Search(
        [FromQuery] AnimeSearchQueryDto query,
        CancellationToken ct = default)
    {
        var result = await _search.SearchAsync(query.Q!, query.Limit!.Value, query.Cursor, query.Year, query.Genres, ct);
        return Ok(result);
    }
}
