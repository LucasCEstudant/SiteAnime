namespace AnimeHub.Application.Helpers;

public static class SeasonHelper
{
    // retorna season e year (UTC)
    public static (string Season, int Year) GetCurrentSeasonUtc()
    {
        var now = DateTime.UtcNow;
        var month = now.Month;

        var season = month switch
        {
            12 or 1 or 2 => "WINTER",
            3 or 4 or 5 => "SPRING",
            6 or 7 or 8 => "SUMMER",
            _ => "FALL"
        };

        return (season, now.Year);
    }
}