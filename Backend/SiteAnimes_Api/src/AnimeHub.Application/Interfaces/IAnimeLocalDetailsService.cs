using AnimeHub.Application.Dtos.AnimeDetailsLocal;

namespace AnimeHub.Application.Interfaces;

public interface IAnimeLocalDetailsService
{
    Task<AnimeLocalDetailsDto?> GetAsync(int animeId, CancellationToken ct);
    Task<bool> UpdateAsync(int animeId, AnimeLocalDetailsUpdateDto dto, CancellationToken ct);
}