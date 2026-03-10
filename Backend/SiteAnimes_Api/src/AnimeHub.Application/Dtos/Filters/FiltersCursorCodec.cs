using System.Text;
using System.Text.Json;

namespace AnimeHub.Application.Dtos.Filters;

public static class FiltersCursorCodec
{
    private static readonly JsonSerializerOptions _json = new(JsonSerializerDefaults.Web);

    public static FiltersCursor DecodeOrNew(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor))
            return new FiltersCursor();

        try
        {
            // base64-url safe -> normal base64
            var b64 = cursor.Replace('-', '+').Replace('_', '/');
            switch (b64.Length % 4)
            {
                case 2: b64 += "=="; break;
                case 3: b64 += "="; break;
            }

            var bytes = Convert.FromBase64String(b64);
            var json = Encoding.UTF8.GetString(bytes);
            return JsonSerializer.Deserialize<FiltersCursor>(json, _json) ?? new FiltersCursor();
        }
        catch
        {
            return new FiltersCursor();
        }
    }

    public static string Encode(FiltersCursor cur)
    {
        var json = JsonSerializer.Serialize(cur, _json);
        var bytes = Encoding.UTF8.GetBytes(json);
        var b64 = Convert.ToBase64String(bytes);

        // base64-url safe
        return b64.TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }
}