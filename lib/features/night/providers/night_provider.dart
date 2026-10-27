// night_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';

final nightMetadataProvider =
    FutureProvider<Map<String, NightMetadata>>((ref) async {
  ref.watch(libraryRevisionProvider);
  final store = await ref.watch(localStoreProvider.future);
  return {
    for (final row in await store.all('night_metadata'))
      row['id'] as String: NightMetadata.fromJson(row)
  };
});
final nightHabitProvider = FutureProvider<NightHabit?>((ref) async {
  ref.watch(libraryRevisionProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  if (!settings.nightSenseEnabled) return null;
  final store = await ref.watch(localStoreProvider.future);
  return detectNightHabit(
      (await store.all('night_observations'))
          .map(NightObservation.fromJson)
          .toList(),
      DateTime.now());
});
final nightSessionProvider =
    StateNotifierProvider<NightSessionController, NightTimer?>(
        (ref) => NightSessionController(ref));

class NightSessionController extends StateNotifier<NightTimer?> {
  NightSessionController(this.ref) : super(null);
  final Ref ref;
  Timer? _timer;
  double _initialVolume = 1;
  bool _updating = false;
  bool _ending = false;
  StreamSubscription<int?>? _trackBoundary;
  StreamSubscription<PositionDiscontinuity>? _discontinuity;
  Future<void> start(
      {Duration duration = const Duration(minutes: 45),
      bool endOfTrack = false}) async {
    if (ref.read(googleCastProvider).casting) {
      throw StateError('Reviens sur cet appareil avant de démarrer Night.');
    }
    await finish();
    final handler = ref.read(audioHandlerProvider);
    if (handler.mediaItem.value == null) {
      throw StateError('Choisis une musique pour la session Night.');
    }
    _initialVolume = handler.player.volume;
    final session = NightTimer(
        startedAt: DateTime.now(), duration: duration, endOfTrack: endOfTrack);
    state = session;
    var previousIndex = handler.player.currentIndex;
    _trackBoundary = handler.player.currentIndexStream.listen((index) {
      final changed = index != previousIndex;
      previousIndex = index;
      if (changed &&
          session.endOfTrack &&
          !DateTime.now().isBefore(session.deadline)) {
        finish(pause: true);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _discontinuity = handler.player.positionDiscontinuityStream.listen((event) {
      if (event.reason == PositionDiscontinuityReason.autoAdvance &&
          session.endOfTrack &&
          !DateTime.now().isBefore(session.deadline)) {
        unawaited(finish(pause: true));
      }
    });
  }

  Future<void> _tick() async {
    if (_updating || _ending || state == null) return;
    _updating = true;
    try {
      final session = state!;
      final player = ref.read(audioHandlerProvider).player;
      final now = DateTime.now();
      if (session.shouldStop(now,
          trackEnded: player.processingState == ProcessingState.completed)) {
        await finish(pause: true);
      } else if (!session.endOfTrack) {
        // Never exceed either the initial or the user's current volume.
        final target = _initialVolume * session.gain(now);
        if (target < player.volume) await player.setVolume(target);
      }
    } finally {
      _updating = false;
    }
  }

  Future<void> finish({bool pause = false}) async {
    if (_ending) return;
    _ending = true;
    try {
      _timer?.cancel();
      _timer = null;
      await _trackBoundary?.cancel();
      _trackBoundary = null;
      await _discontinuity?.cancel();
      _discontinuity = null;
      if (state != null) {
        final session = state!;
        final player = ref.read(audioHandlerProvider).player;
        // Pause before restoring to avoid any unexpected amplification.
        if (pause) await player.pause();
        if (!player.playing) await player.setVolume(_initialVolume);
        if (ref.read(settingsRepositoryProvider).nightSenseEnabled) {
          final actualMinutes =
              DateTime.now().difference(session.startedAt).inMinutes;
          if (actualMinutes > 0) {
            final store = await ref.read(localStoreProvider.future);
            await store.put(
                'night_observations',
                session.startedAt.toIso8601String(),
                NightObservation(session.startedAt, actualMinutes).toJson());
            ref.invalidate(nightHabitProvider);
          }
        }
      }
      state = null;
    } finally {
      _ending = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _trackBoundary?.cancel();
    _discontinuity?.cancel();
    super.dispose();
  }
}
