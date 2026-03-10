import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_state_provider.dart';

/// Painel administrativo — Etapa 12.
/// Placeholder que será expandido com CRUDs nas próximas etapas.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanelTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: l10n.headerProfile,
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          // ── Header ──
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.errorContainer,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 36,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.adminArea,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.adminLoggedAs(authState.email ?? 'admin'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Seções de gerenciamento ──
          Text(
            l10n.adminManagement,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.people_outline,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.adminManageUsers),
                  subtitle: Text(l10n.adminManageUsersDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/users'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.movie_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.adminManageAnimes),
                  subtitle: Text(l10n.adminManageAnimesDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/animes'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.view_carousel_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Banners da Home'),
                  subtitle:
                      const Text('Configurar banners da página inicial'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/banners'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.api_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.adminApiTest),
                  subtitle: Text(l10n.adminApiTestDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/api-test'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Navegação rápida ──
          Text(
            l10n.adminNavigation,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(l10n.adminHomePage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.adminMyProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
