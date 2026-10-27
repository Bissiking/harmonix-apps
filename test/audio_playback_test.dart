import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/audio/audio_handler.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/audio/playback_modes.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';

// Keep the real handler and reactive streams; replace only the native backend.
class _Player extends Mock implements AudioPlayer {
  final indices = BehaviorSubject<int?>.seeded(0);
  final loops = BehaviorSubject<LoopMode>.seeded(LoopMode.off);
  final shuffles = BehaviorSubject<bool>.seeded(false);
  AudioSource? source;

  @override
  Stream<PlaybackEvent> get playbackEventStream =>
      Stream.value(PlaybackEvent(currentIndex: 0));
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Stream<List<IndexedAudioSource>?> get sequenceStream => const Stream.empty();
  @override
  Stream<List<int>?> get shuffleIndicesStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<LoopMode> get loopModeStream => loops.stream;
  @override
  Stream<bool> get shuffleModeEnabledStream => shuffles.stream;
  @override
  LoopMode get loopMode => loops.value;
  @override
  bool get shuffleModeEnabled => shuffles.value;
  @override
  bool get hasNext => true;
  @override
  bool get hasPrevious => false;
  @override
  bool get playing => false;
  @override
  ProcessingState get processingState => ProcessingState.idle;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  Duration? get duration => null;
  @override
  double get speed => 1;

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    shuffles.add(enabled);
    // A native command yields while the seeded streams emit initial values.
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async => loops.add(mode);

  @override
  Future<Duration?> setAudioSource(AudioSource source,
      {bool preload = true,
      int? initialIndex,
      Duration? initialPosition}) async {
    this.source = source;
    indices.add(initialIndex ?? 0);
    return null;
  }

  @override
  Future<void> play() async {}

  Future<void> close() async {
    await indices.close();
    await loops.close();
    await shuffles.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Player player;
  late HarmonixAudioHandler handler;
  setUp(() {
    player = _Player();
    handler = HarmonixAudioHandler(player: player);
  });
  tearDown(() => player.close());

  test('restart restores both saved modes before persisting stream values',
      () async {
    SharedPreferences.setMockInitialValues({
      'flow_shuffle': true,
      'flow_repeat': 'one',
    });
    final settings = SettingsRepository(await SharedPreferences.getInstance());
    // Future.sync also accepts the old void API, so this catches its race.
    await Future.sync(() => bindPlaybackModes(handler, settings));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(player.shuffleModeEnabled, isTrue);
    expect(player.loopMode, LoopMode.one);
    expect(settings.shuffleEnabled, isTrue);
    expect(settings.repeatMode, 'one');

    // The same entrypoints are called by Android Auto and the local player.
    await handler.setShuffleMode(AudioServiceShuffleMode.none);
    await handler.setRepeatMode(AudioServiceRepeatMode.all);
    await Future<void>.delayed(Duration.zero);
    expect(settings.shuffleEnabled, isFalse);
    expect(settings.repeatMode, 'all');
    expect(handler.playbackState.value.repeatMode, AudioServiceRepeatMode.all);
    expect(handler.playbackState.value.systemActions,
        containsAll([MediaAction.setShuffleMode, MediaAction.setRepeatMode]));
  });

  test('opening a player receives navigation even if the queue is unchanged',
      () async {
    final container = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
    ]);
    addTearDown(container.dispose);
    expect(
        await container
            .read(playerNavigationProvider.future)
            .timeout(const Duration(milliseconds: 200)),
        (true, false));
    handler.navigation.value = (false, true);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(playerNavigationProvider).valueOrNull, (false, true));
  });

  test('incremental queue metadata follows loaded items after a skipped title',
      () async {
    const a = MediaItem(id: 'a', title: 'First');
    const missing = MediaItem(id: 'missing', title: 'Unavailable');
    const c = MediaItem(id: 'c', title: 'Third');
    await handler.loadQueueIncremental([a, missing, c], 'https://audio/a',
        initialIndex: 0);
    await handler.appendQueueItem('https://audio/c', c);
    player.indices.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(handler.mediaItem.value?.id, 'c');
    expect(handler.queue.value.map((item) => item.id), ['a', 'c']);
  });

  test('a single title replaces the previous queue metadata', () async {
    const old = MediaItem(id: 'old', title: 'Previous queue');
    const current = MediaItem(id: 'current', title: 'New title');
    await handler.loadQueue([old], ['https://audio/old']);
    await handler.playFromTrackId('current', 'https://audio/current',
        initialMediaItem: current);
    await Future<void>.delayed(Duration.zero);
    expect(handler.mediaItem.value?.id, 'current');
    expect(handler.queue.value, [current]);
  });
}
