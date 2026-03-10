import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Footer premium cinematográfico para a Home page.
///
/// Layout em colunas com branding, navegação rápida e info institucional.
/// Inspirado em footers de plataformas de streaming (Netflix, Crunchyroll).
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgBase,
            AppColors.bgDeep,
          ],
        ),
      ),
      child: Column(
        children: [
          // Separador sutil no topo
          Container(
            height: 1,
            color: AppColors.surfaceVariant,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : 24,
              vertical: 40,
            ),
            child: isWide
                ? _buildWideLayout(context)
                : _buildNarrowLayout(context),
          ),
          // Copyright bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Text(
              AppLocalizations.of(context)!.footerCopyright(DateTime.now().year.toString()),
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branding column
        Expanded(flex: 2, child: _BrandingColumn()),
        const SizedBox(width: 48),
        // Navigation column
        Expanded(child: _NavigationColumn()),
        const SizedBox(width: 32),
        // Resources column
        Expanded(child: _ResourcesColumn()),
        const SizedBox(width: 32),
        // About column
        Expanded(child: _AboutColumn()),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandingColumn(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _NavigationColumn()),
            const SizedBox(width: 24),
            Expanded(child: _ResourcesColumn()),
          ],
        ),
        const SizedBox(height: 24),
        _AboutColumn(),
      ],
    );
  }
}

// ─── Branding Column ─────────────────────────────────────────────

class _BrandingColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo / brand name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.badge + 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'EverAnimes',
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.footerDescription,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        // Social-style icons (decorative)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SocialIcon(icon: Icons.code, tooltip: AppLocalizations.of(context)!.footerGithub),
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.language, tooltip: AppLocalizations.of(context)!.footerWebsite),
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.email_outlined, tooltip: AppLocalizations.of(context)!.footerContact),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Navigation Column ──────────────────────────────────────────

class _NavigationColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _FooterColumn(
      title: l10n.footerNavigation,
      items: [
        l10n.footerHome,
        l10n.footerSearch,
        l10n.footerExploreGenres,
        l10n.footerCurrentSeason,
      ],
    );
  }
}

// ─── Resources Column ───────────────────────────────────────────

class _ResourcesColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _FooterColumn(
      title: l10n.footerResources,
      items: [
        l10n.footerApiAniList,
        l10n.footerApiMal,
        l10n.footerApiKitsu,
        l10n.footerDocs,
      ],
    );
  }
}

// ─── About Column ───────────────────────────────────────────────

class _AboutColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _FooterColumn(
      title: l10n.footerAbout,
      items: [
        l10n.footerPortfolio,
        l10n.footerOpenSource,
        l10n.footerTerms,
        l10n.footerPrivacy,
      ],
    );
  }
}

// ─── Reusable Footer Column ─────────────────────────────────────

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.meta.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              item,
              style: AppTextStyles.meta.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
