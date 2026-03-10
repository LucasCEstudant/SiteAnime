# Admin Banner Management — Implementation Notes

## Current Status

The backend API (**AnimeHub.Api**) currently has **NO** banner/featured management functionality.
There is no:
- `Banner` entity or database table
- `BannersController`
- `IBannerService` / `BannerService`
- DTOs for banner CRUD

The home page's featured section (`featured_section.dart`) currently uses the **first anime from the current-season filter** as the "hero" item.

## Recommended API Schema

To implement admin-controlled banners, the following API additions would be needed:

### Entity

```csharp
public class Banner
{
    public int Id { get; set; }
    public string Title { get; set; } = "";
    public string? Subtitle { get; set; }
    public string ImageUrl { get; set; } = "";
    public string? LinkUrl { get; set; }
    public int? AnimeId { get; set; }
    public string? ExternalId { get; set; }
    public string? ExternalProvider { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ExpiresAtUtc { get; set; }
}
```

### Endpoints

| Method  | Route                | Role  | Description                       |
|---------|---------------------|-------|-----------------------------------|
| GET     | /api/banners        | Public| List active banners (sorted)      |
| GET     | /api/banners/{id}   | Admin | Get single banner                 |
| POST    | /api/banners        | Admin | Create banner                     |
| PUT     | /api/banners/{id}   | Admin | Update banner                     |
| DELETE  | /api/banners/{id}   | Admin | Delete banner                     |
| PATCH   | /api/banners/{id}/order | Admin | Reorder banner              |

### DTOs

```csharp
public record BannerCreateDto(
    string Title,
    string? Subtitle,
    string ImageUrl,
    string? LinkUrl,
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider,
    int SortOrder,
    bool IsActive,
    DateTime? ExpiresAtUtc
);

public record BannerUpdateDto(
    string Title,
    string? Subtitle,
    string ImageUrl,
    string? LinkUrl,
    int? AnimeId,
    string? ExternalId,
    string? ExternalProvider,
    int SortOrder,
    bool IsActive,
    DateTime? ExpiresAtUtc
);
```

## Frontend Implementation Plan

Once the API is implemented:

1. **Data layer**: Create `BannerDto`, `BannerCreateDto`, `BannerUpdateDto` in `lib/features/admin/data/dtos/banner_dtos.dart`
2. **Datasource**: Create `BannersRemoteDatasource` in `lib/features/admin/data/banners_remote_datasource.dart`
3. **Providers**: Create `bannersListProvider` etc. in `lib/features/admin/domain/banners_providers.dart`
4. **Home integration**: Update `featured_section.dart` to use banners API instead of the first season anime
5. **Admin page**: Create banner management page at `lib/features/admin/presentation/admin_banners_page.dart` with drag-to-reorder, image upload, and CRUD form
6. **Routing**: Add `/admin/banners` route
