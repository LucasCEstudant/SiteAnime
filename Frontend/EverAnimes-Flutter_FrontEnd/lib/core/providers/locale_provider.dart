import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chave usada no SharedPreferences para persistir o idioma escolhido.
const _kLocaleKey = 'app_locale';

/// Locales suportados pelo app.
const supportedAppLocales = <Locale>[
  Locale('pt', 'BR'),
  Locale('en', 'US'),
  Locale('es', 'ES'),
  Locale('zh', 'CN'),
];

/// Dados de exibição de cada locale para o seletor de idioma.
class LocaleOption {
  const LocaleOption({
    required this.locale,
    required this.flag,
    required this.label,
  });
  final Locale locale;
  final String flag;
  final String label;
}

const localeOptions = <LocaleOption>[
  LocaleOption(locale: Locale('pt', 'BR'), flag: '🇧🇷', label: 'PT-BR'),
  LocaleOption(locale: Locale('en', 'US'), flag: '🇺🇸', label: 'ENG'),
  LocaleOption(locale: Locale('es', 'ES'), flag: '🇪🇸', label: 'ESP'),
  LocaleOption(locale: Locale('zh', 'CN'), flag: '🇨🇳', label: '中文'),
];

/// Provider global do locale atual.
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Inicia com pt-BR; a sessão restaurada pode sobrescrever.
    return const Locale('pt', 'BR');
  }

  /// Restaura o locale salvo em SharedPreferences.
  /// Se não houver escolha salva, tenta detectar pelo browser.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);

    if (saved != null) {
      final parts = saved.split('_');
      if (parts.length == 2) {
        state = Locale(parts[0], parts[1]);
        return;
      }
    }

    // Tenta detectar pelo locale do browser / sistema.
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final match = supportedAppLocales.where(
      (l) => l.languageCode == systemLocale.languageCode,
    );
    if (match.isNotEmpty) {
      state = match.first;
    }
    // Se não encontrar, mantém pt-BR (padrão do build).
  }

  /// Altera o locale e persiste a escolha.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLocaleKey,
      '${locale.languageCode}_${locale.countryCode}',
    );
  }
}
