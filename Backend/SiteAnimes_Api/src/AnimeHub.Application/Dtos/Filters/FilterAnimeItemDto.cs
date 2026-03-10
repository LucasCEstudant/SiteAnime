using System;
using System.Collections.Generic;
using System.Text;

namespace AnimeHub.Application.Dtos.Filters
{
    public record FilterAnimeItemDto(
        string Source,
        int? Id,
        string? ExternalId,
        string Title,
        int? Year,
        decimal? Score,
        string? CoverUrl,
        IReadOnlyList<string> Genres
    );
}
