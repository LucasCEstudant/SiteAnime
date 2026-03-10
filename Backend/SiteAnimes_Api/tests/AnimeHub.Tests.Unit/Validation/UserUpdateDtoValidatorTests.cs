using AnimeHub.Application.Dtos.Users;
using AnimeHub.Application.Validation.Users;
using AnimeHub.Domain.Entities;
using FluentAssertions;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Users;

public sealed class UserUpdateDtoValidatorTests
{
    [Fact]
    public void Update_DeveFalhar_QuandoNaoEnviaNada()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto(null, null, null);

        var r = sut.TestValidate(dto);

        r.Errors.Should().NotBeEmpty();              
        r.Errors.Should().Contain(e => e.PropertyName == ""); 
    }

    [Fact]
    public void Update_DeveFalhar_EmailInvalido()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto("x", null, null);

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Email!);
    }

    [Fact]
    public void Update_DeveFalhar_PasswordCurto()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto(null, "123", null);

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Password!);
    }

    [Fact]
    public void Update_DeveFalhar_RoleInvalida()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto(null, null, "SuperAdmin");

        var r = sut.TestValidate(dto);

        r.ShouldHaveValidationErrorFor(x => x.Role!);
    }

    [Fact]
    public void Update_DevePassar_QuandoAtualizaEmail()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto("user2@animehub.local", null, null);

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Update_DevePassar_QuandoAtualizaRole()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto(null, null, Roles.User);

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void Update_DevePassar_QuandoAtualizaPassword()
    {
        var sut = new UserUpdateDtoValidator();
        var dto = new UserUpdateDto(null, "NewPass@12345", null);

        var r = sut.TestValidate(dto);

        r.ShouldNotHaveAnyValidationErrors();
    }
}