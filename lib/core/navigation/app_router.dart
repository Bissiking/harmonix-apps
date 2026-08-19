import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/features/bootstrap/presentation/splash_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/album_detail_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/catalog_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_detail_screen.dart';
import 'package:harmonix_apps/features/library/presentation/library_screen.dart';
import 'package:harmonix_apps/features/home/presentation/home_screen.dart';
import 'package:harmonix_apps/features/player/presentation/full_player_screen.dart';
import 'package:harmonix_apps/features/search/presentation/search_screen.dart';
import 'package:harmonix_apps/features/sessions/presentation/sessions_screen.dart';
import 'package:harmonix_apps/features/settings/presentation/settings_screen.dart';
import 'package:harmonix_apps/features/auth/presentation/login_screen.dart';
import 'package:harmonix_apps/shared/widgets/app_shell.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';

GoRouter buildAppRouter({bool requireLogin = false}) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      if (requireLogin && path != '/login') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            name: RouteNames.catalog,
            builder: (_, __) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.trackDetail,
                builder: (_, state) => TrackDetailScreen(
                  trackId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'album/:id',
                name: RouteNames.albumDetail,
                builder: (_, state) => AlbumDetailScreen(
                  albumId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            name: RouteNames.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: '/library',
            name: RouteNames.library,
            builder: (_, __) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/sessions',
            name: RouteNames.sessions,
            builder: (_, __) => const SessionsScreen(),
          ),
          GoRoute(
            path: '/player',
            name: RouteNames.player,
            builder: (_, __) => const FullPlayerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
}
