using System.Text;
using System.Text.Json;

namespace AnimeHub.Application.Dtos.Search
{
    public static class CursorCodec
    {
        private static readonly JsonSerializerOptions JsonOpts = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        public static string Encode(UnifiedSearchCursor cursor)
        {
            var json = JsonSerializer.Serialize(cursor, JsonOpts);
            var bytes = Encoding.UTF8.GetBytes(json);
            return Base64UrlEncode(bytes);
        }

        public static UnifiedSearchCursor DecodeOrNew(string? cursor)
        {
            if (string.IsNullOrWhiteSpace(cursor))
                return new UnifiedSearchCursor();

            try
            {
                var bytes = Base64UrlDecode(cursor);
                var json = Encoding.UTF8.GetString(bytes);
                return JsonSerializer.Deserialize<UnifiedSearchCursor>(json, JsonOpts) ?? new UnifiedSearchCursor();
            }
            catch
            {
                return new UnifiedSearchCursor();
            }
        }

        private static string Base64UrlEncode(byte[] input)
            => Convert.ToBase64String(input).TrimEnd('=').Replace('+', '-').Replace('/', '_');

        private static byte[] Base64UrlDecode(string input)
        {
            var s = input.Replace('-', '+').Replace('_', '/');
            switch (s.Length % 4)
            {
                case 2: s += "=="; break;
                case 3: s += "="; break;
            }
            return Convert.FromBase64String(s);
        }
    }
}
