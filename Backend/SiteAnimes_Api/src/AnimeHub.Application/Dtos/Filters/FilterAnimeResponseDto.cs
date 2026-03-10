using System;
using System.Collections.Generic;
using System.Text;

namespace AnimeHub.Application.Dtos.Filters
{
    public record FilterAnimeResponseDto(
        IReadOnlyList<FilterAnimeItemDto> Items,
        string? NextCursor
    );
}
