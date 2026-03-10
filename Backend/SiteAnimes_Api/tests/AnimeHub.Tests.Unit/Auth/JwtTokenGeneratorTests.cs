using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AnimeHub.Domain.Entities;
using AnimeHub.Infrastructure.Auth;
using FluentAssertions;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace AnimeHub.Tests.Unit.Auth;

public sealed class JwtTokenGeneratorTests
{
    private static JwtTokenGenerator CreateSut()
    {
        var opt = Options.Create(new JwtOptions
        {
            Issuer = "AnimeHub",
            Audience = "AnimeHub",
            Key = "UnitTestKey__MIN_32_CHARS__1234567890__OK",
            ExpiresMinutes = 60,
            RefreshTokenExpiresDays = 7
        });

        return new JwtTokenGenerator(opt);
    }

    [Fact]
    public void Create_DeveGerarJwt()
    {
        var sut = CreateSut();

        var user = new User { Id = 1, Email = "admin@animehub.local", Role = "Admin" };

        var token = sut.Create(user);

        token.Should().NotBeNullOrWhiteSpace();
        token.Split('.').Should().HaveCount(3);
    }

    [Fact]
    public void GetPrincipalFromExpiredToken_DeveAceitarTokenExpirado_QuandoAssinaturaValida()
    {
        var sut = CreateSut();

        // token expirado, mas assinado corretamente
        var expired = CreateExpiredToken(
            issuer: "AnimeHub",
            audience: "AnimeHub",
            key: "UnitTestKey__MIN_32_CHARS__1234567890__OK",
            userId: 1,
            email: "admin@animehub.local",
            role: "Admin"
        );

        var principal = sut.GetPrincipalFromExpiredToken(expired);

        principal.Should().NotBeNull();
        sut.GetUserId(principal!).Should().Be(1);
    }

    [Fact]
    public void GetPrincipalFromExpiredToken_DeveRetornarNull_QuandoAlgoritmoDiferente()
    {
        var sut = CreateSut();

        // HS512 precisa de chave >= 64 bytes (512 bits)
        var key512 = new string('A', 64);

        var token = CreateExpiredTokenWithAlg(
            issuer: "AnimeHub",
            audience: "AnimeHub",
            key: key512,
            alg: SecurityAlgorithms.HmacSha512
        );

        var principal = sut.GetPrincipalFromExpiredToken(token);
        principal.Should().BeNull();
    }

    [Fact]
    public void GetUserId_DeveRetornarNull_QuandoClaimSubAusente()
    {
        var sut = CreateSut();

        var principal = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(JwtRegisteredClaimNames.Email, "x@y.com")
        }, "test"));

        sut.GetUserId(principal).Should().BeNull();
    }

    // -------- helpers --------

    private static string CreateExpiredToken(string issuer, string audience, string key, int userId, string email, string role)
    {
        var now = DateTime.UtcNow;

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.Role, role),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new(JwtRegisteredClaimNames.Iat, EpochTime.GetIntDate(now).ToString(), ClaimValueTypes.Integer64),
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var jwt = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: now.AddMinutes(-1), // expirado
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(jwt);
    }

    private static string CreateExpiredTokenWithAlg(string issuer, string audience, string key, string alg)
    {
        var now = DateTime.UtcNow;

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, "1"),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var creds = new SigningCredentials(signingKey, alg);

        var jwt = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: now.AddMinutes(-1),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(jwt);
    }
}
