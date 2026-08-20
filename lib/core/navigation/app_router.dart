import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/features/bootstrap/presentation/splash_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/album_detail_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/catalog_screen.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_detail_screen.dart';
import 'package:harmonix_apps/features/library/presentation/library_screen.dart';
import 'package:harmonix_apps/features/library/presentation/playlist_detail_screen.dart';
import 'package:harmonix_apps/features/home/presentation/home_screen.dart';
import 'package:harmonix_apps/features/player/presentation/full_player_screen.dart';
import 'package:harmonix_apps/features/rift/presentation/rift_screen.dart';
import 'package:harmonix_apps/features/search/presentation/search_screen.dart';
import 'package:harmonix_apps/features/settings/presentation/settings_screen.dart';
import 'package:harmonix_apps/features/auth/presentation/login_screen.dart';
import 'package:harmonix_apps/shared/widgets/app_shell.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';

Page<void> _smoothPage(Widget child, {String? name}) {
  return CustomTransitionPage<void>(
    name: name,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

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
        pageBuilder: (_, __) => _smoothPage(const SplashScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            pageBuilder: (_, __) => _smoothPage(const HomeScreen()),
          ),
          GoRoute(
            path: '/catalog',
            name: RouteNames.catalog,
            pageBuilder: (_, __) => _smoothPage(const CatalogScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.trackDetail,
                pageBuilder: (_, state) => _smoothPage(
                  TrackDetailScreen(
                    trackId: state.pathParameters['id']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'album/:id',
                name: RouteNames.albumDetail,
                pageBuilder: (_, state) => _smoothPage(
                  AlbumDetailScreen(
                    albumId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            name: RouteNames.search,
            pageBuilder: (_, __) => _smoothPage(const SearchScreen()),
          ),
          GoRoute(
            path: '/library',
            name: RouteNames.library,
            pageBuilder: (_, __) => _smoothPage(const LibraryScreen()),
            routes: [
              GoRoute(
                path: 'playlist/:id',
                name: RouteNames.playlistDetail,
                pageBuilder: (_, state) => _smoothPage(
                  PlaylistDetailScreen(
                    playlistId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            pageBuilder: (_, __) => _smoothPage(const SettingsScreen()),
          ),
          GoRoute(
            path: '/rift',
            name: RouteNames.rift,
            pageBuilder: (_, __) => _smoothPage(const RiftScreen()),
          ),
          GoRoute(
            path: '/player',
            name: RouteNames.player,
            pageBuilder: (_, __) => _smoothPage(const FullPlayerScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        pageBuilder: (_, __) => _smoothPage(const LoginScreen()),
      ),
    ],
  );
}