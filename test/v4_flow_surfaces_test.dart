import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/home/presentation/home_screen.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';
import 'package:harmonix_apps/shared/widgets/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final specs = [
    (
      name: 'mobile',
      size: const Size(390, 844),
      tv: false,
      appearance: FlowAppearance.midnight
    ),
    (
      name: 'tablet',
      size: const Size(768, 1024),
      tv: false,
      appearance: FlowAppearance.midnight
    ),
    (
      name: 'desktop',
      size: const Size(1440, 900),
      tv: false,
      appearance: FlowAppearance.midnight
    ),
    (
      name: 'daylight',
      size: const Size(390, 844),
      tv: false,
      appearance: FlowAppearance.daylight
    ),
    (
      name: 'tv',
      size: const Size(1920, 1080),
      tv: true,
      appearance: FlowAppearance.midnight
    ),
  ];
  for (final spec in specs) {
    testWidgets('Flow ${spec.name}: layout and keyboard navigation',
        (tester) async {
      tester.view.physicalSize = spec.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final settings =
          SettingsRepository(await SharedPreferences.getInstance());
      final router = GoRouter(initialLocation: '/home', routes: [
        ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/search',
              builder: (_, __) =>
                  const Scaffold(body: Text('Recherche ouverte'))),
        ])
      ]);
      addTearDown(router.dispose);
      final key = GlobalKey();
      final dark = AppTheme.dark(spec.appearance.palette);
      final theme =
          spec.appearance == FlowAppearance.daylight ? AppTheme.light : dark;
      if (const bool.fromEnvironment('FLOW_CAPTURE')) {
        await tester.runAsync(() async {
          final root =
              Platform.environment['FLUTTER_ROOT'] ?? 'C:/apps/flutter';
          for (final spec in [
            ('Roboto', 'roboto-regular.ttf'),
            ('MaterialIcons', 'materialicons-regular.otf')
          ]) {
            final file =
                File('$root/bin/cache/artifacts/material_fonts/${spec.$2}');
            if (await file.exists()) {
              final loader = FontLoader(spec.$1)
                ..addFont(Future.value(
                    ByteData.sublistView(await file.readAsBytes())));
              await loader.load();
            }
          }
        });
      }
      await tester.pumpWidget(ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settings),
            isTelevisionProvider.overrideWith((ref) async => spec.tv),
            nowPlayingProvider.overrideWith((ref) => Stream.value(null)),
            deviceTracksProvider.overrideWith((ref) async => []),
            albumsProvider.overrideWith((ref) async => []),
            tracksProvider.overrideWith((ref) async => [
                  for (var i = 0; i < 8; i++)
                    Track(
                        id: 'fixture-$i',
                        title: 'Piste de validation ${i + 1}',
                        artist: 'Catalogue de test',
                        durationMs: 180000)
                ]),
          ],
          child: RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: theme.copyWith(
                      appBarTheme: theme.appBarTheme.copyWith(
                          titleTextStyle: theme.appBarTheme.titleTextStyle
                              ?.copyWith(fontFamily: 'Roboto'))),
                  routerConfig: router))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('FLOW_CAPTURE')) {
        await tester.runAsync(() async {
          final fontFile = File(
              'C:/apps/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
          if (await fontFile.exists()) {
            final loader = FontLoader('Roboto')
              ..addFont(Future.value(
                  ByteData.sublistView(await fontFile.readAsBytes())));
            await loader.load();
          }
        });
        await tester.pump();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final bytes =
              await rendered.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('DOCS/validation');
          await directory.create(recursive: true);
          await File('${directory.path}/flow-${spec.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Recherche ouverte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
