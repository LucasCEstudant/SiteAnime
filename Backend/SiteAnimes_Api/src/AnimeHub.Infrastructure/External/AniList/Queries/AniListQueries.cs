namespace AnimeHub.Infrastructure.External.AniList.Queries;

public static class AniListQueries
{
    public const string Search = @"
        query ($search: String, $page: Int, $perPage: Int) {
          Page(page: $page, perPage: $perPage) {
            media(search: $search, type: ANIME) {
              id
              title { userPreferred }
              description
              startDate { year }
              averageScore
              coverImage { large }
              genres
            }
          }
        }";

    public const string GenreCollection = @"query { GenreCollection }";

    public const string SearchByGenre = @"
        query ($genre: [String], $page: Int, $perPage: Int) {
          Page(page: $page, perPage: $perPage) {
            media(type: ANIME, genre_in: $genre, sort: POPULARITY_DESC) {
              id
              title { userPreferred }
              description
              startDate { year }
              averageScore
              coverImage { large }
              genres
            }
          }
        }";

    public const string SearchByYear = @"
        query ($year: Int, $page: Int, $perPage: Int) {
          Page(page: $page, perPage: $perPage) {
            media(type: ANIME, seasonYear: $year, sort: POPULARITY_DESC) {
              id
              title { userPreferred }
              description
              startDate { year }
              averageScore
              coverImage { large }
              genres
            }
          }
        }";

    public const string SearchBySeason = @"
        query ($season: MediaSeason, $year: Int, $page: Int, $perPage: Int) {
          Page(page: $page, perPage: $perPage) {
            media(type: ANIME, season: $season, seasonYear: $year, sort: POPULARITY_DESC) {
              id
              title { userPreferred }
              description
              startDate { year }
              averageScore
              coverImage { large }
              genres
            }
          }
        }";

    public const string DetailsById = @"
        query ($id: Int) {
          Media(id: $id, type: ANIME) {
            id
            title { userPreferred }
            description(asHtml: false)
            startDate { year }
            averageScore
            episodes
            duration
            coverImage { large }
            genres
            externalLinks { site url }
            streamingEpisodes { title url site }
          }
        }";
}