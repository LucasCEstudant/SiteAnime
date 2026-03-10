using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Interfaces;
using AnimeHub.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using Microsoft.AspNetCore.RateLimiting;

namespace AnimeHub.Api.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _auth;
        private readonly IRegisterService _register;

        public AuthController(IAuthService auth, IRegisterService register)
        {
            _auth = auth;
            _register = register;
        }

        [EnableRateLimiting("auth-register")]
        [HttpPost("register")]
        [SwaggerOperation(
            Summary = "EndPoint publico para criar conta",
            Description = ""
        )]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequestDto dto, CancellationToken ct)
        {
            try
            {
                var created = await _register.RegisterAsync(dto, ct);
                return Created("/api/auth/register", created);
            }
            catch (EmailAlreadyRegisteredException ex)
            {
                return Conflict(new ProblemDetails
                {
                    Title = "E-mail já cadastrado",
                    Detail = ex.Message,
                    Status = StatusCodes.Status409Conflict,
                    Instance = HttpContext.Request.Path
                });
            }
        }

        [EnableRateLimiting("auth-login")]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto req, CancellationToken ct)
        {
            var res = await _auth.LoginAsync(req, ct);
            return res is null ? Unauthorized(new { message = "Credenciais inválidas." }) : Ok(res);
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto req, CancellationToken ct)
        {
            var result = await _auth.RefreshAsync(req, ct);
            if (result is null)
                return Unauthorized(new { message = "Refresh token inválido ou expirado." });

            return Ok(result);
        }

        [HttpPost("revoke")]
        [Authorize]
        public async Task<IActionResult> Revoke([FromBody] RevokeTokenRequestDto req, CancellationToken ct)
        {
            var ok = await _auth.RevokeAsync(req, ct);
            if (!ok)
                return NotFound(new { message = "Refresh token não encontrado." });

            return Ok(new { message = "Refresh token revogado com sucesso." });
        }
    }
}
