namespace AnimeHub.Application.Helpers;

public static class JikanDurationParserHelper
{
    // Exemplos: "23 min per ep", "9 min", "24"
    public static int? ParseMinutes(string? duration)
    {
        if (string.IsNullOrWhiteSpace(duration)) return null;

        // pega o primeiro número que aparecer
        var digits = new string(duration.Where(char.IsDigit).ToArray());
        return int.TryParse(digits, out var minutes) ? minutes : null;
    }
}