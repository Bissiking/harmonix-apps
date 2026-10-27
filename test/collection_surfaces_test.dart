import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';
import 'package:harmonix_apps/features/catalog/presentation/catalog_screen.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/library/presentation/library_screen.dart';
import 'package:harmonix_apps/features/night/presentation/night_screen.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/settings/presentation/settings_screen.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';
import 'package:harmonix_apps/shared/widgets/app_shell.dart';

const capture = bool.fromEnvironment('FLOW_CAPTURE');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Music collection surfaces', () {
    for (final spec in [
      (name: 'mobile', size: const Size(390, 844), scale: 1.0, light: false),
      (name: 'tablet', size: const Size(834, 1112), scale: 1.0, light: false),
      (name: 'desktop', size: const Size(1440, 1000), scale: 1.0, light: false),
      (
        name: 'large-text',
        size: const Size(320, 844),
        scale: 2.0,
        light: false
      ),
      (name: 'daylight', size: const Size(390, 844), scale: 1.0, light: true),
    ]) {
      for (final surface in ['library', 'night', 'catalog', 'settings']) {
        testWidgets(
            'should render $surface on ${spec.name} and keep controls usable',
            (tester) async {
          tester.view.physicalSize = spec.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          PackageInfo.setMockInitialValues(
              appName: 'Harmonix',
              packageName: 'com.harmonix.harmonix_apps',
              version: '4.0.0-dev.2',
              buildNumber: '40001',
              buildSignature: '');
          final settings =
              SettingsRepository(await SharedPreferences.getInstance());
          final tracks = [
            for (final (index, title) in [
              'Dans le vide',
              'Dernier Trajet',
              'Je verrais demain',
              'En Théorie',
              'Ça Va Très Bien',
              'Bella',
              'Amethen Community – The End',
              'CTRL+Z'
            ].indexed)
              Track(
                  id: 'fixture-$index',
                  title: title,
                  artist: 'Catalogue de démonstration',
                  album: index < 4 ? 'AUTOPILOT' : 'MENTAL.EXE',
                  durationMs: 190000 + index * 9000,
                  addedAt: DateTime.utc(2026, 10, 27 - index)),
          ];
          final night = [
            const Track(
                id: 'night-1',
                title: 'Soft Fading Lullaby',
                artist: 'Sélection de démonstration',
                nightEligible: true,
                durationMs: 173000),
            const Track(
                id: 'night-2',
                title: 'Moonlit Reverie',
                artist: 'Sélection de démonstration',
                nightEligible: true,
                durationMs: 206000),
          ];
          var covers = <File>[];
          if (capture) {
            final folder = Directory('D:/DEV/NODEJS/sonora/covers');
            if (folder.existsSync()) {
              covers = folder
                  .listSync()
                  .whereType<File>()
                  .where(
                      (file) => RegExp(r'\.(jpe?g|webp)$').hasMatch(file.path))
                  .toList();
            }
            await tester.runAsync(() async {
              for (final file in covers) {
                final codec =
                    await ui.instantiateImageCodec(await file.readAsBytes());
                final frame = await codec.getNextFrame();
                PaintingBinding.instance.imageCache.putIfAbsent(
                    FileImage(file),
                    () => OneFrameImageStreamCompleter(
                        Future.value(ImageInfo(image: frame.image))));
                codec.dispose();
              }
              for (final font in [
                ('Roboto', 'Roboto-Regular.ttf'),
                ('MaterialIcons', 'MaterialIcons-Regular.otf')
              ]) {
                final file = File(
                    'C:/apps/flutter/bin/cache/artifacts/material_fonts/${font.$2}');
                final loader = FontLoader(font.$1)
                  ..addFont(Future.value(
                      ByteData.sublistView(await file.readAsBytes())));
                await loader.load();
              }
            });
          }
          final all = [...tracks, ...night];
          final files = [
            for (final (index, track) in all.indexed)
              DeviceTrack(
                  track: track,
                  source: MusicSource.downloaded,
                  path: 'fixture',
                  fingerprint: 'fixture',
                  bytes: 1,
                  artworkPath: covers.isEmpty
                      ? null
                      : covers[index % covers.length].path)
          ];
          final router = GoRouter(initialLocation: '/$surface', routes: [
            ShellRoute(
                builder: (_, __, child) => AppShell(child: child),
                routes: [
                  GoRoute(
                      path: '/library',
                      builder: (_, __) => const LibraryScreen()),
                  GoRoute(
                      path: '/night', builder: (_, __) => const NightScreen()),
                  GoRoute(
                      path: '/catalog',
                      builder: (_, __) => const CatalogScreen()),
                  GoRoute(
                      path: '/settings',
                      builder: (_, __) => const SettingsScreen()),
                  GoRoute(
                      path: '/search',
                      builder: (_, __) =>
                          const Scaffold(body: Text('Recherche ouverte'))),
                ])
          ]);
          addTearDown(router.dispose);
          final key = GlobalKey();
          final theme = spec.light
              ? AppTheme.light
              : AppTheme.dark(FlowAppearance.midnight.palette);
          await tester.pumpWidget(ProviderScope(
              overrides: [
                settingsRepositoryProvider.overrideWithValue(settings),
                isTelevisionProvider.overrideWith((ref) async => false),
                nowPlayingProvider.overrideWith((ref) => Stream.value(null)),
                deviceTracksProvider.overrideWith((ref) async => files),
                trackAddedDatesProvider.overrideWith((ref) async => {}),
                nightMetadataProvider.overrideWith((ref) async => {}),
                nightHabitProvider.overrideWith((ref) async => null),
                nightTracksProvider.overrideWith((ref) async => all),
                tracksProvider.overrideWith((ref) async => tracks),
                albumsProvider.overrideWith((ref) async => [
                      Album(
                          id: 'album-1',
                          title: 'AUTOPILOT',
                          artist: 'Catalogue de démonstration',
                          tracks: [tracks[0]]),
                      Album(
                          id: 'album-2',
                          title: 'MENTAL.EXE',
                          artist: 'Catalogue de démonstration',
                          tracks: [tracks[1]]),
                      Album(
                          id: 'album-3',
                          title: 'StoryTime',
                          artist: 'Catalogue de démonstration',
                          tracks: [tracks[2]]),
                    ]),
              ],
              child: RepaintBoundary(
                  key: key,
                  child: MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      theme: theme.copyWith(
                          chipTheme: theme.chipTheme.copyWith(
                              labelStyle: theme.chipTheme.labelStyle
                                  ?.copyWith(fontFamily: 'Roboto')),
                          appBarTheme: theme.appBarTheme.copyWith(
                              titleTextStyle: theme.appBarTheme.titleTextStyle
                                  ?.copyWith(fontFamily: 'Roboto'))),
                      builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.linear(spec.scale)),
                          child: child!),
                      routerConfig: router))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (surface == 'catalog' && spec.size.width < 720) {
            final navigation =
                tester.widget<NavigationBar>(find.byType(NavigationBar));
            expect(navigation.selectedIndex, 2);
            expect((navigation.destinations[2] as NavigationDestination).label,
                'Explorer');
          }
          if (capture) {
            // FileImage decoding runs on the real IO loop, outside fake time.
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 200)));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final boundary = key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final directory = Directory('.impeccable/review');
              await directory.create(recursive: true);
              await File('${directory.path}/$surface-${spec.name}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (surface == 'library') {
            if (spec.scale == 1) {
              expect(find.text('Derniers ajouts'), findsOneWidget);
            }
            await tester.tap(find.byTooltip('Filtrer les titres'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), 'Dernier Trajet');
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
                find.byWidgetPredicate((widget) =>
                    widget is Text && widget.data == 'Dernier Trajet'),
                200,
                scrollable: find
                    .descendant(
                        of: find.byType(CustomScrollView).last,
                        matching: find.byType(Scrollable))
                    .first);
            await tester.pumpAndSettle();
            expect(
                find
                    .text('Dernier Trajet', findRichText: false)
                    .evaluate()
                    .where((element) => element.widget is Text),
                hasLength(1));
            expect(find.text('Dans le vide'), findsNothing);
          }
          if (surface == 'settings') {
            final target = spec.size.width >= 1100
                ? find.widgetWithText(ListTile, 'Connexion')
                : find.widgetWithText(ChoiceChip, 'Connexion');
            await tester.ensureVisible(target);
            await tester.tap(target);
            await tester.pumpAndSettle();
            expect(find.widgetWithText(FilledButton, 'Enregistrer le serveur'),
                findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  });
}
