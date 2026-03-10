using AnimeHub.Application.Dtos.Details;

namespace AnimeHub.Application.Interfaces;

public interface IAnimeDetailsService
{
    Task<AnimeDetailsDto?> GetAsync(string source, int? id, string? externalId, CancellationToken ct);
}