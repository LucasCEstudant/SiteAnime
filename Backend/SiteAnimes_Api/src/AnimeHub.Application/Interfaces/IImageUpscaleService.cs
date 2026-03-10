namespace AnimeHub.Application.Interfaces;

public interface IImageUpscaleService
{
    Task<ImageUpscaleResult> UpscaleAsync(string imageUrl, CancellationToken ct);
}

public sealed record ImageUpscaleResult(byte[] Data, string ContentType);
