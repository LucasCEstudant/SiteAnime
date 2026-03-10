import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../app/shell.dart';
import '../../features/admin/presentation/admin_animes_page.dart';
import '../../features/admin/presentation/admin_banners_page.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/admin_users_page.dart';
import '../../features/api_test/api_test_page.dart';
import '../../features/auth/domain/auth_state_provider.dart';
import '../../features/meta/presentation/genres_page.dart';
import '../../features/mangas/presentation/mangas_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/details/presentation/details_page.dart';
import '../../features/details/presentation/episode_player_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/user_animes/presentation/my_list_page.dart';
import '../widgets/access_denied_page.dart';

/// Rotas que exigem autenticação (qualquer role).
const _authenticatedRoutes = <String>{'/profile', '/my-list'};

/// Prefixo de rotas que exigem role "admin".
const _adminPrefix = '/admin';

/// Fade transition helper — leve, sem peso para debugging.
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Provider que expõe o GoRouter e reage ao estado de autenticação.
/// Etapa 2 + 12: redirect com auth guard + role guard.
/// Etapa 16: fade transitions em todas as rotas.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAdmin = authState.role.toLowerCase() == 'admin';

      // Se a rota exige auth e o usuário não está logado → /login
      if (_authenticatedRoutes.contains(location) && !isAuthenticated) {
        return '/login';
      }

      // Rotas admin: exigem autenticação + role admin.
      if (location.startsWith(_adminPrefix)) {
        if (!isAuthenticated) return '/login';
        if (!isAdmin) return '/access-denied';
      }

      // Se já está logado e tenta acessar /login ou /register → volta para /
      if ((location == '/login' || location == '/register') &&
          isAuthenticated) {
        return '/';
      }

      return null; // sem redirect
    },
    routes: [
      // ── Rotas principais com AppShell (header flutuante) ──────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                _fadePage(state: state, child: const HomePage()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                _fadePage(state: state, child: const ProfilePage()),
          ),
          GoRoute(
            path: '/my-list',
            name: 'my-list',
            pageBuilder: (context, state) =>
                _fadePage(state: state, child: const MyListPage()),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: SearchPage(
                initialQuery:
                    state.uri.queryParameters['q'] ?? '',
                initialGenre:
                    state.uri.queryParameters['genre'] ?? '',
                initialYear: int.tryParse(
                    state.uri.queryParameters['year'] ?? ''),
              ),
            ),
          ),
          GoRoute(
            path: '/genres',
            name: 'genres',
            pageBuilder: (context, state) =>
                _fadePage(state: state, child: const GenresPage()),
          ),
          GoRoute(
            path: '/mangas',
            name: 'mangas',
            pageBuilder: (context, state) =>
                _fadePage(state: state, child: const MangasPage()),
          ),
          GoRoute(
            path: '/anime/:source/:externalId',
            name: 'anime-details',
            pageBuilder: (context, state) {
              final source = state.pathParameters['source']!;
              final externalId = state.pathParameters['externalId']!;
              final localId =
                  source == 'local' ? int.tryParse(externalId) : null;
              return _fadePage(
                state: state,
                child: DetailsPage(
                  source: source,
                  id: localId,
                  externalId: source != 'local' ? externalId : null,
                ),
              );
            },
          ),
        ],
      ),

      // ── Rotas sem shell (auth, admin) ─────────────────────────────────      // ── Player de episódio (imersivo, sem header) ───────────────
      GoRoute(
        path: '/watch/:source/:externalId',
        name: 'episode-player',
        pageBuilder: (context, state) {
          final source = state.pathParameters['source']!;
          final externalId = state.pathParameters['externalId']!;
          final localId =
              source == 'local' ? int.tryParse(externalId) : null;
          final epIndex = int.tryParse(
                state.uri.queryParameters['ep'] ?? '0') ??
              0;
          return _fadePage(
            state: state,
            child: EpisodePlayerPage(
              source: source,
              id: localId,
              externalId: source != 'local' ? externalId : null,
              episodeIndex: epIndex,
            ),
          );
        },
      ),      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const LoginPage()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const RegisterPage()),
      ),
      GoRoute(
        path: '/api-test',
        name: 'api-test',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const ApiTestPage()),
      ),
      // ── Rotas Admin (Etapa 12) ──
      GoRoute(
        path: '/admin',
        name: 'admin',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminDashboardPage()),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminUsersPage()),
      ),
      GoRoute(
        path: '/admin/animes',
        name: 'admin-animes',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminAnimesPage()),
      ),
      GoRoute(
        path: '/admin/banners',
        name: 'admin-banners',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AdminBannersPage()),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access-denied',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AccessDeniedPage()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.pageNotFound,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ),
  );
});
