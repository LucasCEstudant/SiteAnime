import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import '../services/translate_service.dart';
import '../theme/app_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TranslatableText — exibe texto original e dispara tradução em background
//
// • Mostra o texto original imediatamente (sem flash branco / vazio).
// • Enquanto traduz, exibe um shimmer sutil SOBRE o texto (legível por baixo).
// • Ao concluir, troca para o texto traduzido com fade.
// • Se falhar, mantém o texto original sem indicar erro ao usuário.
// ─────────────────────────────────────────────────────────────────────────────

class TranslatableText extends ConsumerStatefulWidget {
  const TranslatableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.sourceLang,
    this.selectable = false,
  });

  /// Texto original (idioma de origem, geralmente japonês / romaji ou pt).
  final String text;

  /// Estilo aplicado ao [Text].
  final TextStyle? style;

  /// Limita linhas visíveis.
  final int? maxLines;

  /// Comportamento de overflow.
  final TextOverflow? overflow;

  final TextAlign? textAlign;

  /// Idioma de origem (ex.: "ja"). Se null, a API detecta automaticamente.
  final String? sourceLang;

  /// When true, renders a [SelectableText] instead of [Text].
  final bool selectable;

  @override
  ConsumerState<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends ConsumerState<TranslatableText> {
  String? _translatedText;
  bool _loading = false;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeTranslate();
  }

  @override
  void didUpdateWidget(TranslatableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = null;
      _maybeTranslate();
    }
  }

  void _maybeTranslate() {
    final locale = ref.read(localeProvider);
    // Se o locale mudou, re-traduz.
    if (_lastLocale != locale) {
      _translatedText = null;
      _lastLocale = locale;
    }
    // Já temos tradução para este locale? Não faz nada.
    if (_translatedText != null) return;

    final targetLang = _localeToTag(locale);
    // Se o idioma de origem é o mesmo do destino, usa original.
    if (widget.sourceLang != null &&
        widget.sourceLang!.toLowerCase() == targetLang.toLowerCase()) {
      _translatedText = widget.text;
      return;
    }

    _requestTranslation(targetLang);
  }

  Future<void> _requestTranslation(String targetLang) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final service = ref.read(translateServiceProvider);
    final result = await service.translate(
      text: widget.text,
      targetLang: targetLang,
      sourceLang: widget.sourceLang,
    );

    if (!mounted) return;
    setState(() {
      _translatedText = result ?? widget.text;
      _loading = false;
    });
  }

  /// Converte [Locale] para tag BCP-47 (ex.: "pt-BR").
  static String _localeToTag(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}-${locale.countryCode}';
    }
    return locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    // Escuta mudanças de locale para re-traduzir.
    final locale = ref.watch(localeProvider);
    if (_lastLocale != locale) {
      // Agendar re-tradução no próximo frame para evitar setState no build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeTranslate();
      });
    }

    final displayText = _translatedText ?? widget.text;

    return Stack(
      children: [
        // Texto principal — sempre visível.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: widget.selectable
              ? SelectableText(
                  displayText,
                  key: ValueKey(displayText),
                  style: widget.style,
                  maxLines: widget.maxLines,
                  textAlign: widget.textAlign,
                )
              : Text(
                  displayText,
                  key: ValueKey(displayText),
                  style: widget.style,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                  textAlign: widget.textAlign,
                ),
        ),

        // Loading shimmer overlay — sutil sobre o texto.
        if (_loading)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _loading ? 0.35 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.card)),
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x22FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
