namespace AnimeHub.Application.Interfaces;

public interface IAniListMetaService
{
    Task<IReadOnlyList<string>> ListAllAvailableGenresAsync(CancellationToken ct);
}