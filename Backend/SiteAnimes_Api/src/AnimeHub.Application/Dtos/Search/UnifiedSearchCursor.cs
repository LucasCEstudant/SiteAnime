
namespace AnimeHub.Application.Dtos.Search
{
    public sealed class UnifiedSearchCursor
    {
        public string? LocalLastTitle { get; set; }
        public int? LocalLastId { get; set; }
        public int? JikanPage { get; set; }
        public int? AniListPage { get; set; }
        public int? KitsuOffset { get; set; }
    }
}
