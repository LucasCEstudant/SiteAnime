using System.ComponentModel.DataAnnotations;

namespace AnimeHub.Api.Options;

public sealed class ImageUpscaleOptions
{
    public const string SectionName = "ImageUpscale";

    [Range(1, 50)]
    public int MaxFileSizeMb { get; init; } = 10;

    [Range(1, 300)]
    public int TimeoutSeconds { get; init; } = 120;

    [Required]
    public string ServiceUrl { get; init; } = "http://realesrgan:8000";

    // Empty list means "allow any host". Configure a non-empty list to restrict hosts again.
    public string[] AllowedHosts { get; init; } = Array.Empty<string>();
}
