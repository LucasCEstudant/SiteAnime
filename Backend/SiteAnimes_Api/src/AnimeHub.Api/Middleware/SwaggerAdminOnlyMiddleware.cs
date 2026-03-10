using AnimeHub.Domain.Entities;
using Microsoft.AspNetCore.Authorization;

namespace AnimeHub.Api.Middleware;

public sealed class SwaggerAdminOnlyMiddleware
{
    private readonly RequestDelegate _next;

    public SwaggerAdminOnlyMiddleware(RequestDelegate next) => _next = next;

    public async Task Invoke(HttpContext context)
    {
        // Só protege rotas do swagger
        var path = context.Request.Path.Value ?? "";
        var isSwagger =
            path.StartsWith("/swagger", StringComparison.OrdinalIgnoreCase);

        if (!isSwagger)
        {
            await _next(context);
            return;
        }

        // Permite swagger em Development sem bloqueio 
        var env = context.RequestServices.GetRequiredService<IWebHostEnvironment>();

        // Se em algum momento quiser Admin-only até em dev, remover/comentar esse if abaixo.
        if (env.IsDevelopment())
        {
            await _next(context);
            return;
        }

        // Exige autenticado
        if (context.User?.Identity?.IsAuthenticated != true)
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        // Exige role Admin (usa seu ClaimTypes.Role)
        if (!context.User.IsInRole(Roles.Admin))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }

        await _next(context);
    }
}