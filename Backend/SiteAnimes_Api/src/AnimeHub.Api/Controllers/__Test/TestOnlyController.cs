using Microsoft.AspNetCore.Mvc;

namespace AnimeHub.Api.Controllers.__Test;

[ApiController]
[ApiExplorerSettings(IgnoreApi = true)] // esconde do Swagger
[Route("api/__test")]
public sealed class TestOnlyController : ControllerBase
{
    private readonly IWebHostEnvironment _env;

    public TestOnlyController(IWebHostEnvironment env) => _env = env;

    [HttpGet("throw")]
    public IActionResult Throw()
    {
        // Só habilita em Testing (integração) pra não existir em prod
        if (!_env.IsEnvironment("Testing"))
            return NotFound();

        throw new InvalidOperationException("Test-only exception");
    }
}