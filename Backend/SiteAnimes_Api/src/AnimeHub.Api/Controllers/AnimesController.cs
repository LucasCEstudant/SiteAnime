using AnimeHub.Application.Dtos.Anime;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers
{
    [SwaggerTag("CRUD DB interno (somente Admin cria/edita/remove; público pode consultar)")]
    [ApiController]
    [Route("api/animes")]
    [Authorize]
    public class AnimesController : ControllerBase
    {
        private readonly IAnimeService _svc;
        public AnimesController(IAnimeService svc) => _svc = svc;

        [HttpGet]
        [AllowAnonymous]
        [SwaggerOperation(
            Summary = "Listar todos animes do DB interno",
            Description = "Retorna todos os animes cadastrados no banco local."
        )]
        public async Task<IActionResult> GetAll(CancellationToken ct)
            => Ok(await _svc.GetAllAsync(ct));

        [HttpGet("{id:int}")]
        [AllowAnonymous]
        [SwaggerOperation(
            Summary = "Listar anime do DB interno por Id",
            Description = ""
        )]
        public async Task<IActionResult> GetById(int id, CancellationToken ct)
        {
            var anime = await _svc.GetByIdAsync(id, ct);
            return anime is null ? NotFound() : Ok(anime);
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [SwaggerOperation(
            Summary = "Cadastrar novo anime",
            Description = ""
        )]
        public async Task<IActionResult> Create([FromBody] AnimeCreateDto dto, CancellationToken ct)
        {
            var created = await _svc.CreateAsync(dto, ct);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin")]
        [SwaggerOperation(
            Summary = "Atualizar Anime por Id",
            Description = ""
        )]
        public async Task<IActionResult> Update(int id, [FromBody] AnimeUpdateDto dto, CancellationToken ct)
        {
            var ok = await _svc.UpdateAsync(id, dto, ct);
            return ok ? NoContent() : NotFound();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "Admin")]
        [SwaggerOperation(
            Summary = "Deletar anime por Id",
            Description = ""
        )]
        public async Task<IActionResult> Delete(int id, CancellationToken ct)
        {
            var ok = await _svc.DeleteAsync(id, ct);
            return ok ? NoContent() : NotFound();
        }
    }
}
