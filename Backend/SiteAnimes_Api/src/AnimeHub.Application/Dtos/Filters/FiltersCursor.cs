using System;
using System.Collections.Generic;
using System.Text;

namespace AnimeHub.Application.Dtos.Filters
{
    public sealed class FiltersCursor
    {
        public string? LocalLastTitle { get; set; }
        public int? LocalLastId { get; set; }

        // externos
        public int? AniListPage { get; set; }
        public int? JikanPage { get; set; }
        public int? KitsuOffset { get; set; }
    }
}
