using System.Text.Json.Serialization;

namespace AnimeHub.Infrastructure.External.Jikan.Models;

public sealed record JikanAnimeItem(
    [property: JsonPropertyName("mal_id")] int Mal_Id,
    [property: JsonPropertyName("title")] string Title,
    [property: JsonPropertyName("synopsis")] string? Synopsis,
    [property: JsonPropertyName("year")] int? Year,
    [property: JsonPropertyName("score")] decimal? Score,
    [property: JsonPropertyName("episodes")] int? Episodes,
    [property: JsonPropertyName("duration")] string? Duration,
    [property: JsonPropertyName("images")] JikanImages? Images,
    [property: JsonPropertyName("genres")] List<JikanGenreItem>? Genres
);

public sealed record JikanGenreItem(
    [property: JsonPropertyName("mal_id")] int MalId,
    [property: JsonPropertyName("name")] string? Name
);