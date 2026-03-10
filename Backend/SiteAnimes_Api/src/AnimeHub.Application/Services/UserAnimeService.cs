using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace AnimeHub.Application.Services;

public sealed class UserAnimeService : IUserAnimeService
{
    private readonly IUserAnimeRepository _repo;
    private readonly IAnimeRepository _animeRepo;
    private readonly ILogger<UserAnimeService> _logger;

    public UserAnimeService(IUserAnimeRepository repo, IAnimeRepository animeRepo, ILogger<UserAnimeService> logger)
    {
        _repo = repo;
        _animeRepo = animeRepo;
        _logger = logger;
    }

    public async Task<UserAnimeDto> AddAsync(int userId, UserAnimeCreateDto dto, CancellationToken ct)
    {
        // duplicate check by external identity
        if (!string.IsNullOrWhiteSpace(dto.ExternalProvider) && !string.IsNullOrWhiteSpace(dto.ExternalId))
        {
            var exists = await _repo.ExistsAsync(userId, dto.ExternalProvider, dto.ExternalId, ct);
            if (exists)
                throw new DuplicateUserAnimeException(dto.ExternalProvider, dto.ExternalId);
        }

        // try to map to local anime
        int? animeId = dto.AnimeId;
        if (animeId.HasValue)
        {
            var local = await _animeRepo.GetByIdAsync(animeId.Value, ct);
            if (local is null)
                animeId = null; // silently clear if invalid
        }

        var entity = new UserAnime
        {
            UserId = userId,
            AnimeId = animeId,
            ExternalId = dto.ExternalId,
            ExternalProvider = dto.ExternalProvider,
            Title = dto.Title,
            Year = dto.Year,
            CoverUrl = dto.CoverUrl,
            Status = dto.Status,
            Score = dto.Score,
            EpisodesWatched = dto.EpisodesWatched,
            Notes = dto.Notes,
            CreatedAtUtc = DateTime.UtcNow
        };

        var saved = await _repo.AddAsync(entity, ct);
        _logger.LogInformation("UserAnime added. UserId={UserId} Id={Id} Title={Title}", userId, saved.Id, saved.Title);
        return ToDto(saved);
    }

    public async Task<UserAnimePagedResponseDto> ListAsync(int userId, string? status, int? year, int page, int pageSize, CancellationToken ct)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var (items, total) = await _repo.GetByUserAsync(userId, status, year, page, pageSize, ct);
        return new UserAnimePagedResponseDto(items.Select(ToDto).ToList(), total, page, pageSize);
    }

    public async Task<UserAnimeDto?> GetByIdAsync(int id, int userId, CancellationToken ct)
    {
        var entity = await _repo.GetByIdAsync(id, userId, ct);
        return entity is null ? null : ToDto(entity);
    }

    public async Task<bool> UpdateAsync(int id, int userId, UserAnimeUpdateDto dto, CancellationToken ct)
    {
        var entity = await _repo.GetByIdAsync(id, userId, ct);
        if (entity is null) return false;

        if (dto.Status is not null) entity.Status = dto.Status;
        if (dto.Score.HasValue) entity.Score = dto.Score;
        if (dto.EpisodesWatched.HasValue) entity.EpisodesWatched = dto.EpisodesWatched;
        if (dto.Notes is not null) entity.Notes = dto.Notes;
        entity.UpdatedAtUtc = DateTime.UtcNow;

        await _repo.UpdateAsync(entity, ct);
        return true;
    }

    public Task<bool> DeleteAsync(int id, int userId, CancellationToken ct)
        => _repo.DeleteAsync(id, userId, ct);

    private static UserAnimeDto ToDto(UserAnime e) => new(
        e.Id, e.AnimeId, e.ExternalId, e.ExternalProvider,
        e.Title, e.Year, e.CoverUrl, e.Status, e.Score,
        e.EpisodesWatched, e.Notes, e.CreatedAtUtc, e.UpdatedAtUtc
    );
}

public sealed class DuplicateUserAnimeException : Exception
{
    public DuplicateUserAnimeException(string provider, string externalId)
        : base($"Anime already in your list (provider={provider}, externalId={externalId}).") { }
}
