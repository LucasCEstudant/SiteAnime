using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using Serilog.Context;

namespace AnimeHub.Api.Observability
{
    public sealed class LogEnrichmentMiddleware
    {
        private readonly RequestDelegate _next;

        public LogEnrichmentMiddleware(RequestDelegate next) => _next = next;

        public async Task Invoke(HttpContext context)
        {
            var sw = Stopwatch.StartNew();
            var traceId = Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier;

            var userId =
                context.User?.FindFirst("sub")?.Value ??
                context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            using (LogContext.PushProperty("TraceId", traceId))
            using (LogContext.PushProperty("HttpMethod", context.Request.Method))
            using (LogContext.PushProperty("Path", context.Request.Path.Value ?? ""))
            using (LogContext.PushProperty("UserId", userId ?? "anonymous"))
            {
                try
                {
                    await _next(context);
                }
                finally
                {
                    sw.Stop();
                    using (LogContext.PushProperty("StatusCode", context.Response.StatusCode))
                    using (LogContext.PushProperty("ElapsedMs", sw.ElapsedMilliseconds))
                    {
                        // Não loga aqui; o Serilog Request Logging vai registrar um summary por request.
                    }
                }
            }
        }
    }
}
