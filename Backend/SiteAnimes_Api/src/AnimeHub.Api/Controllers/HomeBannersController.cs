using AnimeHub.Application.Dtos.HomeBanners;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/home/banners")]
public class HomeBannersController : ControllerBase
{
    private readonly IHomeBannerService _svc;

    public HomeBannersController(IHomeBannerService svc) => _svc = svc;

    [HttpGet]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Listar banners da home",
        Description = "Retorna os slots de banner configurados. Se nenhum banner estiver configurado, retorna lista vazia."
    )]
    public async Task<IActionResult> GetAll(CancellationToken ct)
        => Ok(await _svc.GetAllAsync(ct));

    [HttpPut("{slot}")]
    [Authorize(Roles = "Admin")]
    [SwaggerOperation(
        Summary = "Definir/atualizar anime de um slot de banner",
        Description = "Slots válidos: home-primary, home-secondary. Aceita anime local (AnimeId) ou externo (ExternalId + ExternalProvider)."
    )]
    public async Task<IActionResult> UpdateSlot(
        string slot,
        [FromBody] HomeBannerUpdateDto dto,
        CancellationToken ct)
    {
        var result = await _svc.UpdateSlotAsync(slot, dto, ct);

        if (result is null)
            return BadRequest(new { error = $"Slot '{slot}' is not valid. Allowed: home-primary, home-secondary." });

        return Ok(result);
    }
}
