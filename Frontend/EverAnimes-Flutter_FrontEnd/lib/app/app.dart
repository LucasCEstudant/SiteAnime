import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/locale_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/domain/auth_state_provider.dart';
import '../l10n/app_localizations.dart';

/// Widget raiz do app.
/// Restaura sessão e locale salvos antes de exibir o app.
class EverAnimesApp extends ConsumerStatefulWidget {
  const EverAnimesApp({super.key});

  @override
  ConsumerState<EverAnimesApp> createState() => _EverAnimesAppState();
}

class _EverAnimesAppState extends ConsumerState<EverAnimesApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future.wait([
      ref.read(authStateProvider.notifier).restoreSession(),
      ref.read(localeProvider.notifier).restore(),
    ]);
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto restaura, exibe loader mínimo.
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'EverAnimes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
