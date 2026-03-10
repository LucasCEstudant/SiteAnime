using AnimeHub.Infrastructure.Options;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AnimeHub.Infrastructure.Services;

public sealed class RefreshTokenCleanupService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IOptionsMonitor<RefreshTokenCleanupOptions> _options;
    private readonly ILogger<RefreshTokenCleanupService> _logger;

    public RefreshTokenCleanupService(
        IServiceScopeFactory scopeFactory,
        IOptionsMonitor<RefreshTokenCleanupOptions> options,
        ILogger<RefreshTokenCleanupService> logger)
    {
        _scopeFactory = scopeFactory;
        _options = options;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var cfg = _options.CurrentValue;

            try
            {
                using var scope = _scopeFactory.CreateScope();
                var runner = scope.ServiceProvider.GetRequiredService<RefreshTokenCleanupRunner>();

                var removed = await runner.CleanupAsync(cfg.RevokeRetentionDays, stoppingToken);

                if (removed > 0)
                    _logger.LogInformation("RefreshToken cleanup removed {Count} tokens", removed);
            }
            catch (OperationCanceledException)
            {
                // shutdown
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "RefreshToken cleanup failed");
                // fallback: espera curto pra não loopar em erro
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                continue;
            }

            await Task.Delay(TimeSpan.FromMinutes(cfg.IntervalMinutes), stoppingToken);
        }
    }
}