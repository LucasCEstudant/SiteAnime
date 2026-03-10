using AnimeHub.Application.Dtos.HomeBanners;
using AnimeHub.Application.Interfaces;
using AnimeHub.Domain.Entities;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Application.Services;

public sealed class HomeBannerService : IHomeBannerService
{
    private static readonly HashSet<string> AllowedSlots = new(StringComparer.OrdinalIgnoreCase)
    {
        "home-primary",
        "home-secondary"
    };

    private readonly AppDbContext _db;

    public HomeBannerService(AppDbContext db) => _db = db;

    public async Task<IReadOnlyList<HomeBannerDto>> GetAllAsync(CancellationToken ct)
    {
        var banners = await _db.HomeBanners
            .AsNoTracking()
            .OrderBy(b => b.Slot)
            .ToListAsync(ct);

        return banners.Select(b => new HomeBannerDto(
            Slot: b.Slot,
            AnimeId: b.AnimeId,
            ExternalId: b.ExternalId,
            ExternalProvider: b.ExternalProvider
        )).ToList();
    }

    public async Task<HomeBannerDto?> UpdateSlotAsync(string slot, HomeBannerUpdateDto dto, CancellationToken ct)
    {
        slot = (slot ?? "").Trim().ToLowerInvariant();

        if (!AllowedSlots.Contains(slot))
            return null;

        var banner = await _db.HomeBanners.FirstOrDefaultAsync(b => b.Slot == slot, ct);

        if (banner is null)
        {
            banner = new HomeBanner { Slot = slot };
            _db.HomeBanners.Add(banner);
        }

        if (dto.AnimeId.HasValue)
        {
            banner.AnimeId = dto.AnimeId;
            banner.ExternalId = null;
            banner.ExternalProvider = null;
        }
        else
        {
            banner.AnimeId = null;
            banner.ExternalId = dto.ExternalId;
            banner.ExternalProvider = dto.ExternalProvider;
        }

        banner.UpdatedAtUtc = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return new HomeBannerDto(
            Slot: banner.Slot,
            AnimeId: banner.AnimeId,
            ExternalId: banner.ExternalId,
            ExternalProvider: banner.ExternalProvider
        );
    }
}
