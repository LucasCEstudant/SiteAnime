using AnimeHub.Application.Dtos.Users;
using AnimeHub.Application.Validation.Users;
using AnimeHub.Domain.Entities;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Users;

public sealed class UserCreateDtoValidatorTests
{
    [Fact]
    public void Create_DeveFalhar_EmailInvalido()
    {
        var sut = new UserCreateDtoValidator();
        var dto = new UserCreateDto("x", "Admin@12345", Roles.Admin);

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void Create_DeveFalhar_PasswordCurto()
    {
        var sut = new UserCreateDtoValidator();
        var dto = new UserCreateDto("user@animehub.local", "123", Roles.User);

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void Create_DeveFalhar_RoleInvalida()
    {
        var sut = new UserCreateDtoValidator();
        var dto = new UserCreateDto("user@animehub.local", "User@12345", "SuperAdmin");

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Role);
    }

    [Fact]
    public void Create_DevePassar_QuandoCamposValidos_Admin()
    {
        var sut = new UserCreateDtoValidator();
        var dto = new UserCreateDto("admin2@animehub.local", "Admin@12345", Roles.Admin);

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Create_DevePassar_QuandoCamposValidos_User()
    {
        var sut = new UserCreateDtoValidator();
        var dto = new UserCreateDto("user@animehub.local", "User@12345", Roles.User);

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }
}