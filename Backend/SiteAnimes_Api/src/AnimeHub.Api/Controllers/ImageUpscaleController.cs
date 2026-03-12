using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/images")]
[SwaggerTag("Upscaling de imagens via Real-ESRGAN")]
public sealed class ImageUpscaleController : ControllerBase
{
    private readonly IImageUpscaleService _upscale;

    public ImageUpscaleController(IImageUpscaleService upscale)
        => _upscale = upscale;

    [HttpPost("upscale")]
    [Authorize]
    [EnableRateLimiting("image-upscale")]
    [Produces("image/png")]
    [SwaggerOperation(
        Summary = "Faz upscale 4× de uma imagem usando Real-ESRGAN",
        Description = "Aceita URL de imagem de CDN permitido. Retorna a imagem em PNG com resolução 4× maior."
    )]
    [ProducesResponseType(typeof(FileContentResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<IActionResult> Upscale(
        [FromBody] ImageUpscaleRequestDto request,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.ImageUrl))
            return BadRequest("imageUrl é obrigatório.");

        try
        {
            var result = await _upscale.UpscaleAsync(request.ImageUrl, ct);
            return File(result.Data, result.ContentType);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (TimeoutException)
        {
            return StatusCode(StatusCodes.Status504GatewayTimeout, "Timeout no processamento da imagem.");
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, ex.Message);
        }
    }
}

public sealed record ImageUpscaleRequestDto(string ImageUrl);
