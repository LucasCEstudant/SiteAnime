using AnimeHub.Infrastructure.Auth;
using FluentAssertions;

namespace AnimeHub.Tests.Unit.Auth
{
    public class PasswordHasherTests
    {
        [Fact]
        public void HashPassword_DeveGerarHash_DiferenteDaSenhaOriginal()
        {
            var senha = "Admin@12345";

            var hash = PasswordHasher.Hash(senha);

            hash.Should().NotBeNullOrWhiteSpace();
            hash.Should().NotBe(senha);
        }

        [Fact]
        public void VerifyPassword_DeveRetornarTrue_QuandoSenhaCorreta()
        {
            var senha = "Admin@12345";
            var hash = PasswordHasher.Hash(senha);

            var ok = PasswordHasher.Verify(senha, hash);

            ok.Should().BeTrue();
        }

        [Fact]
        public void VerifyPassword_DeveRetornarFalse_QuandoSenhaIncorreta()
        {
            var hash = PasswordHasher.Hash("Admin@12345");

            var ok = PasswordHasher.Verify("SenhaErrada", hash);

            ok.Should().BeFalse();
        }
    }
}
