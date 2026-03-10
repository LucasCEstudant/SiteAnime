import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens cinematográficos do EverAnimes
// Referência: PlanoAtualizacaoVisualUX.md  §3
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Backgrounds
  static const bgDeep = Color(0xFF000000);
  static const bgBase = Color(0xFF202020); // scaffold dark
  static const surface = Color(0xFF282828); // cards, seções
  static const surfaceVariant = Color(0xFF2E2E2E); // hover leve, borda suave

  // Texto
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3); // metadados, labels

  // Destaque
  static const accent = Color(0xFFE50914); // vermelho streaming
  static const accentDark = Color(0xFFB20710); // hover do accent

  // Avaliações
  static const star = Color(0xFFF5C518); // dourado IMDb-like

  // Overlays (use com Opacity ou Color.withValues)
  static const overlayDark = Color(0xB3000000); // ~70 % preto
  static const overlayMid = Color(0x80000000); // ~50 % preto
  static const overlayLight = Color(0x33000000); // ~20 % preto

  // Seed da paleta Material 3 (mantido para gerar o ColorScheme)
  static const seed = accent;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double card = 8;
  static const double badge = 4;
  static const double btn = 4;
  static const double input = 12;
  static const double dialog = 16;
  static const double chip = 8;
  static const double circle = 9999;
}

abstract final class AppTextStyles {
  static const fontFamily = 'Segoe UI';

  /// 32sp / w700 — Título hero / featured
  static const titleHero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// 18sp / w600 — Cabeçalhos de seções
  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  /// 16sp / w600 — Títulos de cards
  static const titleCard = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 14sp / w400 — Corpo de texto, sinopses
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// 12sp / w400 — Metadados, labels
  static const meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  /// 14sp / w600 — Botões
  static const btn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive breakpoints
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppBreakpoints {
  /// Width below which we consider the device "mobile".
  static const double mobile = 600;

  /// Width at or above which we consider the device "tablet".
  static const double tablet = 900;

  /// Returns `true` when the screen width is below [mobile] (600px).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
}
