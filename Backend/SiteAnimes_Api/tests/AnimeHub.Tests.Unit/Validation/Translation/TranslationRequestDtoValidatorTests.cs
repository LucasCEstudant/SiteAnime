using AnimeHub.Application.Dtos.Translation;
using AnimeHub.Application.Validation.Translation;
using FluentValidation.TestHelper;

namespace AnimeHub.Tests.Unit.Validation.Translation;

public class TranslationRequestDtoValidatorTests
{
    private readonly TranslationRequestDtoValidator _sut = new();

    [Fact]
    public void DeveFalhar_QuandoTextVazio()
    {
        var dto = new TranslationRequestDto("", "pt-BR");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Text);
    }

    [Fact]
    public void DeveFalhar_QuandoTextExcede5000Chars()
    {
        var dto = new TranslationRequestDto(new string('A', 5001), "pt-BR");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Text);
    }

    [Fact]
    public void DeveFalhar_QuandoTargetLangVazio()
    {
        var dto = new TranslationRequestDto("Hello", "");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.TargetLang);
    }

    [Fact]
    public void DeveFalhar_QuandoTargetLangNaoSuportado()
    {
        var dto = new TranslationRequestDto("Hello", "fr-FR");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.TargetLang);
    }

    [Fact]
    public void DeveFalhar_QuandoSourceLangNaoSuportado()
    {
        var dto = new TranslationRequestDto("Hello", "pt-BR", SourceLang: "xx-YY");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.SourceLang);
    }

    [Fact]
    public void DeveFalhar_QuandoFormatInvalido()
    {
        var dto = new TranslationRequestDto("Hello", "pt-BR", Format: "xml");
        var r = _sut.TestValidate(dto);
        r.ShouldHaveValidationErrorFor(x => x.Format);
    }

    [Fact]
    public void DevePassar_QuandoCamposValidos()
    {
        var dto = new TranslationRequestDto("Hello world", "pt-BR");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DevePassar_QuandoSourceLangInformado()
    {
        var dto = new TranslationRequestDto("Hello", "pt-BR", SourceLang: "en-US");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void DevePassar_QuandoFormatHtml()
    {
        var dto = new TranslationRequestDto("Hello", "pt-BR", Format: "html");
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }

    [Theory]
    [InlineData("pt-BR")]
    [InlineData("en-US")]
    [InlineData("es-ES")]
    [InlineData("zh-CN")]
    public void DevePassar_ParaTodosIdiomasSuportados(string lang)
    {
        var dto = new TranslationRequestDto("Text", lang);
        var r = _sut.TestValidate(dto);
        r.ShouldNotHaveAnyValidationErrors();
    }
}
