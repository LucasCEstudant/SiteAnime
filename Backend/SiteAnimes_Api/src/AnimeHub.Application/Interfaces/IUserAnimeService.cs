using AnimeHub.Application.Dtos.UserAnimes;

namespace AnimeHub.Application.Interfaces;

public interface IUserAnimeService
{
    Task<UserAnimeDto> AddAsync(int userId, UserAnimeCreateDto dto, CancellationToken ct);
    Task<UserAnimePagedResponseDto> ListAsync(int userId, string? status, int? year, int page, int pageSize, CancellationToken ct);
    Task<UserAnimeDto?> GetByIdAsync(int id, int userId, CancellationToken ct);
    Task<bool> UpdateAsync(int id, int userId, UserAnimeUpdateDto dto, CancellationToken ct);
    Task<bool> DeleteAsync(int id, int userId, CancellationToken ct);
}
