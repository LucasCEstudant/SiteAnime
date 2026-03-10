using System.Text.Json.Serialization;

namespace AnimeHub.Infrastructure.External.Jikan.Models;

public sealed record JikanImages(
    [property: JsonPropertyName("jpg")] JikanJpg? Jpg
);

public sealed record JikanJpg(
    [property: JsonPropertyName("image_url")] string? Image_Url
);