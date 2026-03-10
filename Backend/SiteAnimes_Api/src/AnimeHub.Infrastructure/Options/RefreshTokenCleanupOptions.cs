using System.ComponentModel.DataAnnotations;

namespace AnimeHub.Infrastructure.Options;

public sealed class RefreshTokenCleanupOptions
{
    public const string SectionName = "RefreshTokenCleanup";

    [Range(1, 1440)]
    public int IntervalMinutes { get; init; } = 60;

    [Range(1, 365)]
    public int RevokeRetentionDays { get; init; } = 7;
}