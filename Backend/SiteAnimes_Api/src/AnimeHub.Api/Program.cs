using AnimeHub.Api.Observability;
using AnimeHub.Api.Options;
using AnimeHub.Api.Validation;
using AnimeHub.Application.Interfaces;
using AnimeHub.Application.Services;
using AnimeHub.Application.Services.Providers;
using AnimeHub.Application.Validation.Anime;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Auth;
using AnimeHub.Infrastructure.External.AniList;
using AnimeHub.Infrastructure.External.Common;
using AnimeHub.Infrastructure.External.Jikan;
using AnimeHub.Infrastructure.External.Kitsu;
using AnimeHub.Infrastructure.External.Translation;
using AnimeHub.Infrastructure.Persistence;
using AnimeHub.Infrastructure.Persistence.Seed;
using AnimeHub.Infrastructure.Repositories;
using Microsoft.Extensions.Caching.Memory;
using AnimeHub.Infrastructure.Services;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Serilog;
using System.Diagnostics;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

// Allow DateTime with Kind != Utc to be sent to PostgreSQL timestamptz columns
// (safe for migration from SQL Server where Kind is often Unspecified)
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("frontend", p =>
    {
        if (allowedOrigins is { Length: > 0 })
        {
            p.WithOrigins(allowedOrigins)
             .AllowAnyHeader()
             .AllowAnyMethod();
        }
    });
});

builder.Host.UseSerilog((ctx, lc) =>
    lc.ReadFrom.Configuration(ctx.Configuration)
      .Enrich.FromLogContext()
);

builder.Services.AddHealthChecks()
    // readiness: verifica DB (AppDbContext)
    .AddDbContextCheck<AppDbContext>("db", tags: new[] { "ready" });

builder.Services.AddHostedService<RefreshTokenCleanupService>();

builder.Services.AddRateLimiter(options =>
{
    // Resposta padr�o quando estoura
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    var cfg = builder.Configuration
        .GetSection(RateLimitingOptions.SectionName)
        .Get<RateLimitingOptions>()!;

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ip,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = cfg.Global.PermitLimit,         // x por minuto
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Login mais agressivo
    options.AddPolicy("auth-login", httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"login:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = cfg.AuthLogin.PermitLimit,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Register mais agressivo ainda
    options.AddPolicy("auth-register", httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"register:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = cfg.AuthRegister.PermitLimit,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Translation endpoint
    options.AddPolicy("translation", httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"translation:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = cfg.Translation.PermitLimit,
                Window = TimeSpan.FromSeconds(cfg.Translation.WindowSeconds),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Image upscale endpoint
    options.AddPolicy("image-upscale", httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"upscale:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = cfg.ImageUpscale.PermitLimit,
                Window = TimeSpan.FromSeconds(cfg.ImageUpscale.WindowSeconds),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Image proxy endpoint
    options.AddPolicy("image-proxy", httpContext =>
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        var permitLimit = cfg.ImageProxy.PermitLimit > 0
            ? cfg.ImageProxy.PermitLimit
            : 300;
        var windowSeconds = cfg.ImageProxy.WindowSeconds > 0
            ? cfg.ImageProxy.WindowSeconds
            : 60;

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"image-proxy:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = permitLimit,
                Window = TimeSpan.FromSeconds(windowSeconds),
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });
});

builder.Services.AddOpenTelemetry()
.WithTracing(tracing =>
{
    tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter();
})
.WithMetrics(metrics =>
{
    metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter();
});

builder.Services.AddControllers(options =>
{
    options.Filters.Add<FluentValidationActionFilter>();
});

builder.Services.AddOptions<AnimeHub.Infrastructure.Options.RefreshTokenCleanupOptions>()
    .Bind(builder.Configuration.GetSection(AnimeHub.Infrastructure.Options.RefreshTokenCleanupOptions.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddOptions<ExternalApisOptions>()
    .Bind(builder.Configuration.GetSection(ExternalApisOptions.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddOptions<RateLimitingOptions>()
    .Bind(builder.Configuration.GetSection(RateLimitingOptions.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddOptions<TranslationOptions>()
    .Bind(builder.Configuration.GetSection(TranslationOptions.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddOptions<ImageUpscaleOptions>()
    .Bind(builder.Configuration.GetSection(ImageUpscaleOptions.SectionName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddValidatorsFromAssemblyContaining<AnimeCreateDtoValidator>();

builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = ctx =>
    {
        ctx.ProblemDetails.Extensions["traceId"] =
            Activity.Current?.TraceId.ToString() ?? ctx.HttpContext.TraceIdentifier;

        ctx.ProblemDetails.Extensions["path"] = ctx.HttpContext.Request.Path.Value;
    };
});

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problem = new ValidationProblemDetails(context.ModelState)
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Validation failed",
            Type = "https://httpstatuses.com/400",
            Instance = context.HttpContext.Request.Path
        };

        problem.Extensions["traceId"] =
            Activity.Current?.TraceId.ToString() ?? context.HttpContext.TraceIdentifier;

        return new BadRequestObjectResult(problem)
        {
            ContentTypes = { "application/problem+json" }
        };
    };
});

builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

builder.Services.AddScoped<IAnimeRepository, AnimeRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<JwtTokenGenerator>();
builder.Services.AddScoped<IAnimeService, AnimeService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAnimeSearchService, AnimeSearchService>();
builder.Services.AddScoped<IAnimeFiltersService, AnimeFiltersService>();
builder.Services.AddScoped<IAnimeDetailsService, AnimeDetailsService>();
builder.Services.AddScoped<IAnimeLocalDetailsService, AnimeLocalDetailsService>();
builder.Services.AddScoped<IAniListMetaService, AniListMetaService>();
builder.Services.AddScoped<IHomeBannerService, HomeBannerService>();
builder.Services.AddScoped<IUserManagementService, UserManagementService>();
builder.Services.AddScoped<IRegisterService, RegisterService>();

builder.Services.AddScoped<IUserAnimeRepository, UserAnimeRepository>();
builder.Services.AddScoped<IUserAnimeService, UserAnimeService>();

builder.Services.AddScoped<IImageUpscaleService>(sp =>
{
    var opts = sp.GetRequiredService<IOptions<ImageUpscaleOptions>>().Value;
    var http = sp.GetRequiredService<IHttpClientFactory>().CreateClient("ImageProxy");
    var upscaleClient = sp.GetRequiredService<IHttpClientFactory>().CreateClient("UpscaleService");
    return new ImageUpscaleService(
        http,
        upscaleClient,
        sp.GetRequiredService<ILogger<ImageUpscaleService>>(),
        opts.ServiceUrl,
        opts.TimeoutSeconds,
        opts.MaxFileSizeMb,
        opts.AllowedHosts);
});

builder.Services.AddScoped<IAnimeExternalProvider, JikanProvider>();
builder.Services.AddScoped<IAnimeExternalProvider, AniListProvider>();
builder.Services.AddScoped<IAnimeExternalProvider, KitsuProvider>();

builder.Services.AddScoped<ITranslationProvider, LibreTranslateProvider>();
builder.Services.AddScoped<ITranslationService>(sp =>
{
    var opts = sp.GetRequiredService<IOptions<TranslationOptions>>().Value;
    return new TranslationService(
        sp.GetRequiredService<ITranslationProvider>(),
        sp.GetRequiredService<IMemoryCache>(),
        sp.GetRequiredService<ILogger<TranslationService>>(),
        TimeSpan.FromMinutes(opts.CacheTtlMinutes));
});

builder.Services.AddScoped<RefreshTokenCleanupRunner>();

builder.Services.AddMemoryCache();

builder.Services.AddSingleton<JikanRateLimiter>();
builder.Services.AddSingleton<AniListRateLimiter>();
builder.Services.AddSingleton<KitsuRateLimiter>();

// Jikan (named client + factory)
builder.Services.AddHttpClient<RestJsonClient>("JikanRest", (sp, c) =>
{
    var cfg = sp.GetRequiredService<IOptions<ExternalApisOptions>>().Value;
    c.BaseAddress = new Uri(cfg.Jikan.BaseUrl);
    c.Timeout = TimeSpan.FromSeconds(cfg.Jikan.TimeoutSeconds);
});
builder.Services.AddScoped<JikanClient>(sp =>
{
    var http = sp.GetRequiredService<IHttpClientFactory>().CreateClient("JikanRest");
    return new JikanClient(new RestJsonClient(http));
});

// AniList (typed GraphQL client + AniListClient factory)
builder.Services.AddHttpClient<GraphQlClient>((sp, c) =>
{
    var cfg = sp.GetRequiredService<IOptions<ExternalApisOptions>>().Value;
    c.BaseAddress = new Uri(cfg.AniList.BaseUrl);
    c.Timeout = TimeSpan.FromSeconds(cfg.AniList.TimeoutSeconds);
});

builder.Services.AddScoped<AniListClient>(sp =>
    new AniListClient(sp.GetRequiredService<GraphQlClient>()));

// Kitsu (typed client)
builder.Services.AddHttpClient<KitsuClient>((sp, c) =>
{
    var cfg = sp.GetRequiredService<IOptions<ExternalApisOptions>>().Value;
    c.BaseAddress = new Uri(cfg.Kitsu.BaseUrl);
    c.Timeout = TimeSpan.FromSeconds(cfg.Kitsu.TimeoutSeconds);
    c.DefaultRequestHeaders.Add("Accept", cfg.Kitsu.Accept);
});

// HttpClient usado pelo ImageProxyController para buscar imagens de CDNs externos
builder.Services.AddHttpClient("ImageProxy", c =>
{
    c.DefaultRequestHeaders.UserAgent.ParseAdd(
        "Mozilla/5.0 (compatible; AnimeHub/1.0; +https://github.com/JacaroasProgramaticas)");
    c.Timeout = TimeSpan.FromSeconds(15);
});

// HttpClient para o microserviço Real-ESRGAN (upscale)
builder.Services.AddHttpClient("UpscaleService", (sp, c) =>
{
    var opts = sp.GetRequiredService<IOptions<ImageUpscaleOptions>>().Value;
    c.Timeout = TimeSpan.FromSeconds(Math.Max(5, opts.TimeoutSeconds) + 30);
});

// LibreTranslate (typed client)
builder.Services.AddHttpClient<LibreTranslateClient>((sp, c) =>
{
    var cfg = sp.GetRequiredService<IOptions<TranslationOptions>>().Value;
    c.BaseAddress = new Uri(cfg.BaseUrl);
    // set a slightly higher timeout than the provider timeout to allow for the full request
    c.Timeout = TimeSpan.FromSeconds(Math.Max(5, cfg.TimeoutSeconds) + 10);
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "AnimeHub API",
        Version = "v1"
    });

    options.AddSecurityDefinition("bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Cole apenas o token JWT (sem 'Bearer')."
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("bearer", document)] = []
    });

    options.EnableAnnotations();
});

var jwt = builder.Configuration.GetSection("Jwt");
var issuer = jwt["Issuer"]!;
var audience = jwt["Audience"]!;
var key = jwt["Key"]!;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = issuer,
            ValidateAudience = true,
            ValidAudience = audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

//middleware de enrichment + request logging
app.UseMiddleware<LogEnrichmentMiddleware>();

app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diag, http) =>
    {
        diag.Set("TraceId", System.Diagnostics.Activity.Current?.TraceId.ToString() ?? http.TraceIdentifier);
        diag.Set("UserId", http.User?.FindFirst("sub")?.Value ?? "anonymous");
    };

    options.GetLevel = (http, elapsedMs, ex) =>
    {
        if (ex is not null) return Serilog.Events.LogEventLevel.Error;

        var status = http.Response.StatusCode;

        return status switch
        {
            >= 500 => Serilog.Events.LogEventLevel.Error,
            >= 400 => Serilog.Events.LogEventLevel.Warning,
            _ => Serilog.Events.LogEventLevel.Debug
        };
    };
});

//Global exception handling
app.UseExceptionHandler();

// HTTPS: enable redirection only when an HTTPS URL or certificate is configured
{
    var urls = app.Configuration["ASPNETCORE_URLS"] ?? Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? string.Empty;
    var hasHttpsInUrls = urls.IndexOf("https", StringComparison.OrdinalIgnoreCase) >= 0;
    var certPath = app.Configuration["ASPNETCORE_Kestrel__Certificates__Default__Path"] ?? Environment.GetEnvironmentVariable("ASPNETCORE_Kestrel__Certificates__Default__Path");

    if (hasHttpsInUrls || !string.IsNullOrEmpty(certPath))
    {
        app.UseHttpsRedirection();
    }
}

// Routing primeiro (necess�rio para EnableRateLimiting)
app.UseRouting();

// CORS (s� se tiver origins configuradas)
if (allowedOrigins is { Length: > 0 })
{
    app.UseCors("frontend");
}

// Rate limiting deve rodar depois do UseRouting quando usa [EnableRateLimiting]
app.UseRateLimiter();

// Auth
app.UseAuthentication();
app.UseAuthorization();

// Swagger Admin-only (em Production) � tem que vir ANTES do swagger e DEPOIS do auth
app.UseMiddleware<AnimeHub.Api.Middleware.SwaggerAdminOnlyMiddleware>();

// Swagger
app.UseSwagger();
app.UseSwaggerUI();

// Health checks (mapeia endpoints)
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = r => r.Tags.Contains("ready"),
    ResultStatusCodes =
    {
        [HealthStatus.Healthy] = StatusCodes.Status200OK,
        [HealthStatus.Degraded] = StatusCodes.Status200OK,
        [HealthStatus.Unhealthy] = StatusCodes.Status503ServiceUnavailable
    }
});

app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var env = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>();

    if (!env.IsEnvironment("Testing"))
    {
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var cfg = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        await DbSeeder.SeedAsync(db, cfg, CancellationToken.None);
    }
}

app.Run();

public partial class Program { }


