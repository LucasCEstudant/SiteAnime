using AnimeHub.Application.Dtos.Auth;
using AnimeHub.Application.Validation.Auth;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Auth;

public sealed class RegisterRequestDtoValidatorTests
{
    [Fact]
    public void Register_DeveFalhar_EmailInvalido()
    {
        var sut = new RegisterRequestDtoValidator();
        var dto = new RegisterRequestDto("x", "User@12345");

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void Register_DeveFalhar_PasswordVazio()
    {
        var sut = new RegisterRequestDtoValidator();
        var dto = new RegisterRequestDto("user@animehub.local", "");

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void Register_DeveFalhar_PasswordCurto()
    {
        var sut = new RegisterRequestDtoValidator();
        var dto = new RegisterRequestDto("user@animehub.local", "123");

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void Register_DevePassar_QuandoCamposValidos()
    {
        var sut = new RegisterRequestDtoValidator();
        var dto = new RegisterRequestDto("user@animehub.local", "User@12345");

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }
}