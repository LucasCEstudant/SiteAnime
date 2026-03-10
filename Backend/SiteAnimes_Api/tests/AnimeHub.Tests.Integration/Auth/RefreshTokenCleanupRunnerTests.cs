using AnimeHub.Domain.Entities;
using AnimeHub.Infrastructure.Persistence;
using AnimeHub.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace AnimeHub.Tests.Integration.Auth;

public sealed class RefreshTokenCleanupRunnerTests : IClassFixture<ApiFactory>
{
    private readonly ApiFactory _factory;

    public RefreshTokenCleanupRunnerTests(ApiFactory factory) => _factory = factory;

    [Fact]
    public async Task CleanupAsync_DeveRemover_TokensExpirados_E_RevogadosAntigos()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var runner = scope.ServiceProvider.GetRequiredService<RefreshTokenCleanupRunner>();

        var now = DateTime.UtcNow;

        // Usuário seed (admin) já existe na ApiFactory; pega o primeiro user
        var userId = await db.Users.Select(x => x.Id).FirstAsync(TestContext.Current.CancellationToken);

        // 1) expirado -> deve remover
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            Token = "expired-1",
            CreatedAtUtc = now.AddDays(-10),
            ExpiresAtUtc = now.AddMinutes(-1)
        });

        // 2) revogado antigo (>7 dias) -> deve remover
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            Token = "revoked-old-1",
            CreatedAtUtc = now.AddDays(-20),
            ExpiresAtUtc = now.AddDays(10),
            RevokedAtUtc = now.AddDays(-8),
            ReplacedByToken = "x"
        });

        // 3) válido -> NÃO deve remover
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            Token = "valid-1",
            CreatedAtUtc = now,
            ExpiresAtUtc = now.AddDays(10)
        });

        await db.SaveChangesAsync(TestContext.Current.CancellationToken);

        // Act
        var removed = await runner.CleanupAsync(
            revokeRetentionDays: 7,
            ct: TestContext.Current.CancellationToken
        );

        // Assert
        removed.Should().Be(2);

        var remaining = await db.RefreshTokens
            .Select(x => x.Token)
            .ToListAsync(TestContext.Current.CancellationToken);

        remaining.Should().Contain("valid-1");
        remaining.Should().NotContain("expired-1");
        remaining.Should().NotContain("revoked-old-1");
    }
}