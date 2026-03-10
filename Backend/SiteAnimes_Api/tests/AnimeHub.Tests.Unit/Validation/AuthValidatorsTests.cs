using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Validation.Auth;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation;

public class AuthValidatorsTests
{
    [Fact]
    public void Login_DeveFalhar_EmailInvalido()
    {
        var sut = new LoginRequestDtoValidator();
        var dto = new LoginRequestDto("x", "123456");
        var r = sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void Login_DeveFalhar_PasswordVazio()
    {
        var sut = new LoginRequestDtoValidator();
        var dto = new LoginRequestDto("admin@animehub.local", "");
        var r = sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void Refresh_DeveFalhar_QuandoCamposVazios()
    {
        var sut = new RefreshTokenRequestDtoValidator();
        var dto = new RefreshTokenRequestDto("", "");
        var r = sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.AccessToken);
        r.ShouldHaveValidationErrorFor(x => x.RefreshToken);
    }

    [Fact]
    public void Revoke_DeveFalhar_QuandoRefreshVazio()
    {
        var sut = new RevokeTokenRequestDtoValidator();
        var dto = new RevokeTokenRequestDto("");
        var r = sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.RefreshToken);
    }

    [Fact]
    public void Login_DevePassar_QuandoCamposValidos()
    {
        var sut = new LoginRequestDtoValidator();
        var dto = new LoginRequestDto("admin@animehub.local", "Admin@12345");
        var r = sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}