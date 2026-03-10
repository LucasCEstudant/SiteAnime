import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/top_header.dart';
import '../../l10n/app_localizations.dart';
import '../auth/domain/auth_state_provider.dart';

/// Tela de perfil autenticado — Etapa 11.
/// Exibe dados da sessão atual (email, role) e permite logout.
/// Rota protegida: redireciona para /login se não autenticado.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileLogoutTitle),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);

    await ref.read(authStateProvider.notifier).logout();

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final email = authState.email ?? l10n.profileUser;
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final isAdmin = authState.role.toLowerCase() == 'admin';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          top: kTopHeaderHeight + 16,
          left: 24,
          right: 24,
          bottom: 32,
        ),
        children: [
          // ── Avatar + nome ──
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 18,
                    color: isAdmin
                        ? colorScheme.error
                        : colorScheme.onSecondaryContainer,
                  ),
                  label: Text(
                    isAdmin ? l10n.profileAdmin : l10n.profileUser,
                    style: TextStyle(
                      color: isAdmin
                          ? colorScheme.error
                          : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isAdmin
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  side: BorderSide.none,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Informações da Conta ──
          Text(
            l10n.profileAccountInfo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.email),
                  subtitle: Text(email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.profileAccessRole),
                  subtitle: Text(isAdmin ? l10n.profileAdmin : l10n.profileRegularUser),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.verified_user_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.profileSessionStatus),
                  subtitle: Text(l10n.profileSessionActive),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Ações ──
          Text(
            l10n.profileActions,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                if (isAdmin) ...[
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings,
                      color: colorScheme.error,
                    ),
                    title: Text(l10n.profileAdminPanel),
                    subtitle: Text(l10n.profileManageDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/admin'),
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(l10n.myList),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/my-list'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(l10n.profileHomePage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(l10n.profileSearchAnimes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/search'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    l10n.profileLogoutTitle,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  trailing: _loggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.chevron_right, color: colorScheme.error),
                  onTap: _loggingOut ? null : _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
