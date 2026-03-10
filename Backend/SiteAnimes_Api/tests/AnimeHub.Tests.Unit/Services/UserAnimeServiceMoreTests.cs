using AnimeHub.Application.Dtos.UserAnimes;
using AnimeHub.Application.Services;
using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using Moq;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;

namespace AnimeHub.Tests.Unit.Services;

public class UserAnimeServiceMoreTests
{
    private readonly Mock<IUserAnimeRepository> _repo = new();
    private readonly Mock<IAnimeRepository> _animeRepo = new();

    private UserAnimeService CreateSut()
        => new UserAnimeService(_repo.Object, _animeRepo.Object, Mock.Of<Microsoft.Extensions.Logging.ILogger<UserAnimeService>>());

    [Fact]
    public async Task UpdateAsync_ReturnsFalse_WhenNotFound()
    {
        _repo.Setup(r => r.GetByIdAsync(1, 2, It.IsAny<CancellationToken>())).ReturnsAsync((UserAnime?)null);
        var sut = CreateSut();
        var dto = new UserAnimeUpdateDto("completed", 8.5m, 12, "note");

        var ok = await sut.UpdateAsync(1, 2, dto, CancellationToken.None);

        Assert.False(ok);
    }

    [Fact]
    public async Task UpdateAsync_UpdatesEntity_WhenFound()
    {
        var existing = new UserAnime { Id = 1, UserId = 2, Title = "T", Score = 7m, EpisodesWatched = 1, Notes = "a" };
        _repo.Setup(r => r.GetByIdAsync(1, 2, It.IsAny<CancellationToken>())).ReturnsAsync(existing);
        _repo.Setup(r => r.UpdateAsync(It.IsAny<UserAnime>(), It.IsAny<CancellationToken>())).Returns(Task.CompletedTask).Verifiable();

        var sut = CreateSut();
        var dto = new UserAnimeUpdateDto("completed", 8.58m, 12, "updated note");

        var ok = await sut.UpdateAsync(1, 2, dto, CancellationToken.None);

        Assert.True(ok);
        _repo.Verify(r => r.UpdateAsync(It.Is<UserAnime>(u => u.Id == 1 && u.Score == 8.58m && u.Status == "completed" && u.EpisodesWatched == 12 && u.Notes == "updated note"), It.IsAny<CancellationToken>()));
    }

    [Fact]
    public async Task DeleteAsync_DelegatesToRepository()
    {
        _repo.Setup(r => r.DeleteAsync(1, 2, It.IsAny<CancellationToken>())).ReturnsAsync(true);
        var sut = CreateSut();

        var ok = await sut.DeleteAsync(1, 2, CancellationToken.None);

        Assert.True(ok);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsDto_WhenFound()
    {
        var entity = new UserAnime
        {
            Id = 5,
            UserId = 10,
            AnimeId = 42,
            ExternalId = "ext",
            ExternalProvider = "Jikan",
            Title = "Titulo",
            Year = 2020,
            CoverUrl = "http://img",
            Status = "completed",
            Score = 8.58m,
            EpisodesWatched = 24,
            Notes = "n",
        };
        _repo.Setup(r => r.GetByIdAsync(5, 10, It.IsAny<CancellationToken>())).ReturnsAsync(entity);

        var sut = CreateSut();
        var dto = await sut.GetByIdAsync(5, 10, CancellationToken.None);

        Assert.NotNull(dto);
        Assert.Equal(8.58m, dto!.Score);
        Assert.Equal(42, dto.AnimeId);
        Assert.Equal("Titulo", dto.Title);
    }

    [Fact]
    public async Task ListAsync_ReturnsPagedResult()
    {
        var list = new List<UserAnime>
        {
            new UserAnime { Id = 1, UserId = 2, Title = "A", CreatedAtUtc = System.DateTime.UtcNow },
            new UserAnime { Id = 2, UserId = 2, Title = "B", CreatedAtUtc = System.DateTime.UtcNow }
        };
        _repo.Setup(r => r.GetByUserAsync(2, null, null, 1, 20, It.IsAny<CancellationToken>())).ReturnsAsync((list, list.Count));

        var sut = CreateSut();
        var res = await sut.ListAsync(2, null, null, 1, 20, CancellationToken.None);

        Assert.Equal(list.Count, res.TotalCount);
        Assert.Equal(2, res.Items.Count);
        Assert.Contains(res.Items, i => i.Title == "A");
    }
}
