using AnimeHub.Application.Dtos.Users;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace AnimeHub.Api.Controllers;

[ApiController]
[Route("api/users")]
[Authorize(Roles = Roles.Admin)]
[SwaggerTag("Admin: gerenciamento de usuários")]
public sealed class UsersController : ControllerBase
{
    private readonly IUserManagementService _svc;

    public UsersController(IUserManagementService svc) => _svc = svc;

    [HttpPost]
    [SwaggerOperation(Summary = "Criar usuário (Admin/User)")]
    public async Task<IActionResult> Create([FromBody] UserCreateDto dto, CancellationToken ct)
    {
        var created = await _svc.CreateAsync(dto, ct);

        // Evita o problema de "No route matches..." com Async sufixo e/ou action name
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpGet]
    [SwaggerOperation(Summary = "Listar usuários")]
    public async Task<IActionResult> GetAll(CancellationToken ct)
        => Ok(await _svc.GetAllAsync(ct));

    [HttpGet("{id:int}")]
    [SwaggerOperation(Summary = "Obter usuário por Id")]
    public async Task<IActionResult> GetById(int id, CancellationToken ct)
    {
        var u = await _svc.GetByIdAsync(id, ct);
        return u is null ? NotFound() : Ok(u);
    }

    [HttpPut("{id:int}")]
    [SwaggerOperation(Summary = "Atualizar usuário (email/role/password)")]
    public async Task<IActionResult> Update(int id, [FromBody] UserUpdateDto dto, CancellationToken ct)
    {
        var ok = await _svc.UpdateAsync(id, dto, ct);
        return ok ? NoContent() : NotFound();
    }

    [HttpDelete("{id:int}")]
    [SwaggerOperation(Summary = "Deletar usuário")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var ok = await _svc.DeleteAsync(id, ct);
        return ok ? NoContent() : NotFound();
    }
}