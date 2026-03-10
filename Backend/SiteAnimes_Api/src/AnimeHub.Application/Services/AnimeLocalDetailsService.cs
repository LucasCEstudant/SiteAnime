using AnimeHub.Application.Dtos.AnimeDetailsLocal;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Application.Services;

public sealed class AnimeLocalDetailsService : IAnimeLocalDetailsService
{
    private readonly AppDbContext _db;
    public AnimeLocalDetailsService(AppDbContext db) => _db = db;

    public async Task<AnimeLocalDetailsDto?> GetAsync(int animeId, CancellationToken ct)
    {
        var a = await _db.Animes.AsNoTracking().FirstOrDefaultAsync(x => x.Id == animeId, ct);
        if (a is null) return null;

        return new AnimeLocalDetailsDto(
            Id: a.Id,
            EpisodeCount: a.EpisodeCount,
            EpisodeLengthMinutes: a.EpisodeLengthMinutes,
            ExternalLinks: a.ExternalLinks.Select(x => new AnimeLocalExternalLinkDto(x.Site, x.Url)).ToList(),
            StreamingEpisodes: a.StreamingEpisodes.Select(x => new AnimeLocalStreamingEpisodeDto(x.Title, x.Url, x.Site)).ToList()
        );
    }

    public async Task<bool> UpdateAsync(int animeId, AnimeLocalDetailsUpdateDto dto, CancellationToken ct)
    {
        var a = await _db.Animes.FirstOrDefaultAsync(x => x.Id == animeId, ct);
        if (a is null) return false;

        a.EpisodeCount = dto.EpisodeCount;
        a.EpisodeLengthMinutes = dto.EpisodeLengthMinutes;

        a.ExternalLinks = (dto.ExternalLinks ?? new()).Select(x => new AnimeExternalLink
        {
            Site = x.Site ?? "",
            Url = x.Url ?? ""
        }).ToList();

        a.StreamingEpisodes = (dto.StreamingEpisodes ?? new()).Select(x => new AnimeStreamingEpisode
        {
            Title = x.Title ?? "",
            Url = x.Url ?? "",
            Site = x.Site
        }).ToList();

        a.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
        return true;
    }
}