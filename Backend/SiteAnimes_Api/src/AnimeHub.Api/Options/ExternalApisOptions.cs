using System.ComponentModel.DataAnnotations;

namespace AnimeHub.Api.Options;

public sealed class ExternalApisOptions
{
    public const string SectionName = "ExternalApis";

    [Required] public ExternalApiOptions Jikan { get; init; } = new();
    [Required] public ExternalApiOptions AniList { get; init; } = new();
    [Required] public KitsuApiOptions Kitsu { get; init; } = new();
}

public class ExternalApiOptions
{
    [Required] public string BaseUrl { get; init; } = "";
    [Range(1, 120)] public int TimeoutSeconds { get; init; } = 15;
}

public sealed class KitsuApiOptions : ExternalApiOptions
{
    [Required] public string Accept { get; init; } = "application/vnd.api+json";
}