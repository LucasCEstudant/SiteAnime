import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/top_header.dart';

/// Página placeholder para a seção de Mangás.
///
/// Exibe uma mensagem "Em desenvolvimento" com uma animação de livro/mangá
/// e efeito de partículas estilizado.
class MangasPage extends StatefulWidget {
  const MangasPage({super.key});

  @override
  State<MangasPage> createState() => _MangasPageState();
}

class _MangasPageState extends State<MangasPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );

    _rotateAnim = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Padding(
        padding: const EdgeInsets.only(top: kTopHeaderHeight),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone animado de mangá
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Transform.rotate(
                      angle: _rotateAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFE040FB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Título
              Text(
                l10n.mangasTitle,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Subtítulo
              Text(
                l10n.mangasInDevelopment,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Descrição
              SizedBox(
                width: 360,
                child: Text(
                  l10n.mangasDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Barra de progresso animada
              _AnimatedProgressBar(animation: _ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso estilizada que pulsa suavemente.
class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        final progress = 0.3 + 0.15 * math.sin(animation.value * math.pi);
        return Column(
          children: [
            SizedBox(
              width: 200,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      AppColors.surfaceVariant.withValues(alpha: 0.4),
                  color: AppColors.accent.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.mangasProgress((progress * 100).toInt().toString()),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      },
    );
  }
}
