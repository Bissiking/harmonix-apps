import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/home/presentation/home_screen.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 2.0]) {
    testWidgets('home renders at 320px with ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const tracks = [
        Track(
          id: 'track-1',
          title: 'Une nuit harmonieuse',
          artist: 'Harmonix',
          durationMs: 180000,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(
              SettingsRepository(preferences),
            ),
            tracksProvider.overrideWith((ref) async => tracks),
            albumsProvider.overrideWith((ref) async => const <Album>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark(ThemePalette.fallback),
            themeMode: ThemeMode.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Une nuit harmonieuse'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
