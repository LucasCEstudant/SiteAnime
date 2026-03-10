using AnimeHub.Application.Dtos.Filters;
using AnimeHub.Application.Dtos.Queries;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/animes/filters")]
[SwaggerTag("Filtros e descoberta de animes (agrega fontes locais + externas).")]
public class AnimeFiltersController : ControllerBase
{
    private readonly IAnimeFiltersService _svc;
    public AnimeFiltersController(IAnimeFiltersService svc) => _svc = svc;

    [HttpGet("genre")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Filtrar por gênero (agregado)",
        Description = "Retorna animes filtrados por gênero agregando fontes externas (AniList + Kitsu). Paginação via cursor."
    )]
    [ProducesResponseType(typeof(FilterAnimeResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ByGenre(
        [FromQuery] AnimeFilterGenreQueryDto query,
        CancellationToken ct = default)
        => Ok(await _svc.ByGenreAsync(query.Genre!, query.Limit!.Value, query.Cursor, ct));

    [HttpGet("year")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Filtrar por ano (agregado)",
        Description = "Retorna animes do ano informado (banco local + fonte externa AniList). Paginação via cursor."
    )]
    [ProducesResponseType(typeof(FilterAnimeResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ByYear(
        [FromQuery] AnimeFilterYearQueryDto query,
        CancellationToken ct = default)
        => Ok(await _svc.ByYearAsync(query.Year!.Value, query.Limit!.Value, query.Cursor, ct));

    [HttpGet("season/now")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Animes da temporada atual (agregado)",
        Description = "Retorna animes da temporada atual agregando fontes externas (Jikan + AniList). Paginação via cursor."
    )]
    [ProducesResponseType(typeof(FilterAnimeResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SeasonNow(
        [FromQuery] AnimeSeasonNowQueryDto query,
        CancellationToken ct = default)
        => Ok(await _svc.SeasonNowAsync(query.Limit!.Value, query.Cursor, ct));
}