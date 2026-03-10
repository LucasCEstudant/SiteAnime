namespace AnimeHub.Api.Options;

public sealed class SwaggerOptions
{
    public const string SectionName = "Swagger";
    public bool ProtectInProduction { get; init; } = true;
}