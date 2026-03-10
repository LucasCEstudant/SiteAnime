using System.ComponentModel.DataAnnotations;

namespace AnimeHub.Api.Options;

public sealed class RateLimitingOptions
{
    public const string SectionName = "RateLimiting";

    [Required] public FixedWindowOptions Global { get; init; } = new();
    [Required] public FixedWindowOptions AuthLogin { get; init; } = new();
    [Required] public FixedWindowOptions AuthRegister { get; init; } = new();
    [Required] public FixedWindowOptions Translation { get; init; } = new();
    [Required] public FixedWindowOptions ImageUpscale { get; init; } = new();
    [Required] public FixedWindowOptions ImageProxy { get; init; } = new();
}

public sealed class FixedWindowOptions
{
    [Range(1, 10_000)] public int PermitLimit { get; init; }
    [Range(1, 3600)] public int WindowSeconds { get; init; }
}