import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';

import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/player/presentation/full_player_screen.dart';
import 'package:harmonix_apps/features/player/presentation/mini_player_bar.dart';
import 'package:harmonix_apps/features/player/providers/dynamic_colors_provider.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class _TestCast extends GoogleCastController {
  _TestCast(super.ref);

  void update(Duration position) {
    state = state.copyWith(
      casting: true,
      isPlaying: true,
      deviceName: 'Salon',
      position: position,
      duration: const Duration(seconds: 100),
    );
  }
}

void main() {
  for (final full in [false, true]) {
    testWidgets('${full ? 'Full' : 'Mini'} player isolates position ticks',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        SharedPreferences.setMockInitialValues({});
        final settings =
            SettingsRepository(await SharedPreferences.getInstance());
        final positions = StreamController<Duration>.broadcast();
        final states = StreamController<PlaybackState>.broadcast();
        addTearDown(positions.close);
        addTearDown(states.close);
        const item = MediaItem(
          id: 'shadowpulse',
          title: 'Shadowpulse',
          artist: 'Gio',
          duration: Duration(seconds: 100),
        );
        late _TestCast cast;
        var files = <DeviceTrack>[];
        await tester.pumpWidget(ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settings),
            deviceTracksProvider.overrideWith((ref) async => files),
            isTelevisionProvider.overrideWith((ref) async => false),
            playerAmbientProvider.overrideWith((ref) async => Colors.purple),
            nowPlayingProvider.overrideWith((ref) => Stream.value(item)),
            playbackQueueProvider.overrideWith((ref) => Stream.value([item])),
            playbackDurationProvider.overrideWith(
                (ref) => Stream.value(const Duration(seconds: 100))),
            playbackPositionProvider.overrideWith((ref) => positions.stream),
            playbackStateStreamProvider.overrideWith((ref) => states.stream),
            googleCastProvider.overrideWith((ref) => cast = _TestCast(ref)),
          ],
          child: MaterialApp(
            home: full
                ? const FullPlayerScreen()
                : const Scaffold(bottomNavigationBar: MiniPlayerBar()),
          ),
        ));
        await tester.pumpAndSettle();
        states.add(PlaybackState(playing: true));
        await tester.pumpAndSettle();
        final artwork = tester.widget<TrackArtwork>(find.byType(TrackArtwork));
        final cover = find.descendant(
            of: find.byType(TrackArtwork), matching: find.byType(ClipRRect));
        final coverBeforeDownload = tester.widget(cover);
        files = [
          const DeviceTrack(
            track:
                Track(id: 'shadowpulse', title: 'Shadowpulse', artist: 'Gio'),
            source: MusicSource.downloaded,
            path: 'audio/shadowpulse.mp3',
            fingerprint: 'download-hash',
            bytes: 1000,
          )
        ];
        final container = ProviderScope.containerOf(
            tester.element(find.byType(TrackArtwork)));
        container.invalidate(deviceTracksProvider);
        container.read(libraryRevisionProvider.notifier).state++;
        await tester.pumpAndSettle();
        expect(tester.widget(cover), same(coverBeforeDownload),
            reason: 'Finishing an audio download does not change its artwork');

        // Audio and buffering events keep progress live without recreating the
        // cover and tooltip anchors on every frame.
        for (var second = 1; second <= 12; second++) {
          positions.add(Duration(seconds: second));
          states.add(PlaybackState(
            playing: true,
            updatePosition: Duration(seconds: second),
            bufferedPosition: Duration(seconds: second + 5),
          ));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.widget(find.byType(TrackArtwork)), same(artwork));
        }
        if (full) {
          expect(tester.widget<ProgressBar>(find.byType(ProgressBar)).progress,
              const Duration(seconds: 12));
        } else {
          expect(
              tester
                  .widget<LinearProgressIndicator>(
                      find.byType(LinearProgressIndicator))
                  .value,
              .12);
          expect(find.bySemanticsLabel('Progression du titre'), findsOneWidget);
        }
        states.add(PlaybackState(playing: false));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Lire'), findsOneWidget);
        expect(
            tester
                .getSemantics(find.byTooltip('Lire'))
                .getSemanticsData()
                .tooltip,
            'Lire');

        cast.update(const Duration(seconds: 20));
        await tester.pumpAndSettle();
        final castArtwork = tester.widget(find.byType(TrackArtwork));
        cast.update(const Duration(seconds: 30));
        await tester.pump();
        expect(tester.widget(find.byType(TrackArtwork)), same(castArtwork));
        if (full) {
          expect(tester.widget<ProgressBar>(find.byType(ProgressBar)).progress,
              const Duration(seconds: 30));
        } else {
          expect(
              tester
                  .widget<LinearProgressIndicator>(
                      find.byType(LinearProgressIndicator))
                  .value,
              .3);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  }
}
