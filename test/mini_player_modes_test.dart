import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/presentation/mini_player_bar.dart';
import 'package:harmonix_apps/features/player/providers/dynamic_colors_provider.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';

class _NoCast extends GoogleCastController {
  _NoCast(super.ref);
}

void main() {
  Future<void> pumpBar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final settings =
        SettingsRepository(await SharedPreferences.getInstance());
    final states = StreamController<PlaybackState>.broadcast();
    addTearDown(states.close);
    const item = MediaItem(
      id: 'shadowpulse',
      title: 'Shadowpulse',
      artist: 'Gio',
      duration: Duration(seconds: 100),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        deviceTracksProvider.overrideWith((ref) async => <DeviceTrack>[]),
        isTelevisionProvider.overrideWith((ref) async => false),
        playerAmbientProvider.overrideWith((ref) async => Colors.purple),
        nowPlayingProvider.overrideWith((ref) => Stream.value(item)),
        playbackQueueProvider.overrideWith((ref) => Stream.value([item])),
        playbackDurationProvider.overrideWith(
            (ref) => Stream.value(const Duration(seconds: 100))),
        playbackPositionProvider.overrideWith(
            (ref) => Stream.value(Duration.zero)),
        playbackStateStreamProvider.overrideWith((ref) => states.stream),
        googleCastProvider.overrideWith((ref) => _NoCast(ref)),
      ],
      child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: MiniPlayerBar())),
    ));
    states.add(PlaybackState(
      playing: true,
      shuffleMode: AudioServiceShuffleMode.none,
      repeatMode: AudioServiceRepeatMode.none,
    ));
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  testWidgets('wide layouts carry the Aléatoire and Boucle toggles',
      (tester) async {
    await pumpBar(tester, const Size(1200, 800));
    expect(find.byTooltip('Activer la lecture aléatoire'), findsOneWidget);
    expect(find.byTooltip('Activer la répétition'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone widths keep only the three transport controls',
      (tester) async {
    await pumpBar(tester, const Size(390, 844));
    expect(find.byTooltip('Activer la lecture aléatoire'), findsNothing);
    expect(find.byTooltip('Activer la répétition'), findsNothing);
    expect(find.byTooltip('Titre suivant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
