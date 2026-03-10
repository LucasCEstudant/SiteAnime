namespace AnimeHub.Infrastructure.External.Common;

public sealed record GraphQlRequest(string Query, object Variables);