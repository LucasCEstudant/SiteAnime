using AnimeHub.Application.Dtos.HomeBanners;

namespace AnimeHub.Application.Interfaces;

public interface IHomeBannerService
{
    Task<IReadOnlyList<HomeBannerDto>> GetAllAsync(CancellationToken ct);
    Task<HomeBannerDto?> UpdateSlotAsync(string slot, HomeBannerUpdateDto dto, CancellationToken ct);
}
