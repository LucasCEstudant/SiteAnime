using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Services;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using Moq;

namespace AnimeHub.Tests.Unit.Services;

public class UserAnimeServiceTests
{
    private readonly Mock<IUserAnimeRepository> _repo = new();
    private readonly Mock<IAnimeRepository> _animeRepo = new();

    private UserAnimeService CreateSut()
        => new UserAnimeService(_repo.Object, _animeRepo.Object, Mock.Of<Microsoft.Extensions.Logging.ILogger<UserAnimeService>>());

    [Fact]
    public async Task AddAsync_DeveLancarDuplicateQuandoExternalProviderIdExistir()
    {
        _repo.Setup(r => r.ExistsAsync(2, "Jikan", "57658", It.IsAny<CancellationToken>())).ReturnsAsync(true);
        var sut = CreateSut();

        var dto = new UserAnimeCreateDto(null, "57658", "Jikan", "Titulo", 2026, null, "completed", 8, 2, null);

        await Assert.ThrowsAsync<AnimeHub.Application.Services.DuplicateUserAnimeException>(() => sut.AddAsync(2, dto, CancellationToken.None));
    }

    [Fact]
    public async Task AddAsync_DeveIgnorarAnimeId_QuandoInvalido()
    {
        _animeRepo.Setup(a => a.GetByIdAsync(999, It.IsAny<CancellationToken>())).ReturnsAsync((Anime?)null);
        _repo.Setup(r => r.ExistsAsync(2, It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);
        _repo.Setup(r => r.AddAsync(It.IsAny<UserAnime>(), It.IsAny<CancellationToken>())).ReturnsAsync((UserAnime u, CancellationToken ct) => { u.Id = 1; return u; });

        var sut = CreateSut();
        var dto = new UserAnimeCreateDto(999, "57658", "Jikan", "Titulo", 2026, null, "completed", 8, 2, null);

        var result = await sut.AddAsync(2, dto, CancellationToken.None);
        Assert.Null(result.AnimeId);
        Assert.Equal("57658", result.ExternalId);
    }
}
