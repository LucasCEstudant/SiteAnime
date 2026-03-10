using AnimeHub.Application.Dtos.Translation;
using AnimeHub.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[SwaggerTag("Tradução de texto via LibreTranslate (self-hosted)")]
[ApiController]
[Route("api/translate")]
[AllowAnonymous]
[EnableRateLimiting("translation")]
public class TranslationController : ControllerBase
{
    private readonly ITranslationService _svc;
    private readonly ILogger<TranslationController> _logger;

    public TranslationController(ITranslationService svc, ILogger<TranslationController> logger)
    {
        _svc = svc;
        _logger = logger;
    }

    [HttpPost]
    [SwaggerOperation(
        Summary = "Traduzir texto",
        Description = "Traduz texto usando LibreTranslate self-hosted. Suporta pt-BR, en-US, es-ES, zh-CN."
    )]
    [ProducesResponseType(typeof(TranslationResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status502BadGateway)]
    public async Task<IActionResult> Translate([FromBody] TranslationRequestDto request, CancellationToken ct)
    {
        try
        {
            var result = await _svc.TranslateAsync(request, ct);
            return Ok(result);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "LibreTranslate request failed");

            return Problem(
                title: "Translation provider unavailable",
                detail: "O serviço de tradução não está disponível no momento. Tente novamente mais tarde.",
                statusCode: StatusCodes.Status502BadGateway
            );
        }
        catch (TaskCanceledException ex) when (!ct.IsCancellationRequested)
        {
            _logger.LogWarning(ex, "LibreTranslate request timed out");

            return Problem(
                title: "Translation provider timeout",
                detail: "O serviço de tradução demorou demais para responder.",
                statusCode: StatusCodes.Status504GatewayTimeout
            );
        }
    }
}
