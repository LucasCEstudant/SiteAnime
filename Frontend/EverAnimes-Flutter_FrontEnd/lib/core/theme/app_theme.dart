import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Design tokens e temas do EverAnimes.
/// Etapa 1 (tokens-theme): paleta cinematográfica streaming — AppColors, AppRadius, AppTextStyles.
abstract final class AppTheme {
  // ── Constantes de design (via AppRadius) ──
  static const double _cardRadius = AppRadius.card;       // 8
  static const double _inputRadius = AppRadius.input;     // 12
  static const double _buttonRadius = AppRadius.btn;      // 4
  static const double _dialogRadius = AppRadius.dialog;   // 16
  static const double _chipRadius = AppRadius.chip;       // 8
  static const double _cardElevation = 2;

  // ── Tipografia (via AppTextStyles) ──
  static const _fontFamily = AppTextStyles.fontFamily;

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return base.copyWith(
      // titleHero  → headlineLarge: 32sp w700
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w700,
      ),
      // sectionTitle → titleLarge: 18sp w600
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      // titleCard → titleMedium: 16sp w600
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // body → bodyLarge: 14sp w400
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 14,
        height: 1.5,
      ),
      // body → bodyMedium: 14sp w400
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 14,
        height: 1.5,
      ),
      // meta → bodySmall: 12sp w400
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: _fontFamily,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  // ── Componentes compartilhados ──

  static final _cardTheme = CardThemeData(
    elevation: _cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardRadius),
    ),
    clipBehavior: Clip.antiAlias,
  );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      );

  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.4,
      ),
    ),
  );

  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.4,
      ),
    ),
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      elevation: 1,
    ),
  );

  static final _dialogTheme = DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_dialogRadius),
    ),
  );

  static final _chipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_chipRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  static const _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 1,
  );

  static final _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardRadius),
    ),
  );

  // ── Temas finais ──

  /// Tema escuro (principal).
  static final ThemeData dark = _buildTheme(Brightness.dark);

  /// Tema claro.
  static final ThemeData light = _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Gera o esquema base a partir do accent vermelho cinematográfico.
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: AppColors.seed, // #E50914 vermelho streaming
    );
    final cs = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.bgBase : cs.surface, // #121212 no dark
      textTheme: _buildTextTheme(brightness),
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme(cs),
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      dialogTheme: _dialogTheme,
      chipTheme: _chipTheme,
      snackBarTheme: _snackBarTheme,
      dividerTheme: const DividerThemeData(space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
      ),
    );
  }
}
