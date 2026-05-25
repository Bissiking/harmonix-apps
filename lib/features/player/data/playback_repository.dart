import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/providers/playback_client_provider.dart';
import 'package:harmonix_apps/core/models/playback_state_model.dart';
import 'package:harmonix_apps/core/models/resume_info.dart';

part 'playback_repository.g.dart';

class PlaybackRepository {
  PlaybackRepository(this._ref);

  final dynamic _ref;

  Future<PlaybackStateModel> getState() =>
      _ref.read(playbackClientProvider).getState();

  Future<void> saveState(PlaybackStateModel s) =>
      _ref.read(playbackClientProvider).saveState({
        'trackId': s.trackId,
        'positionMs': s.positionMs,
        'volume': s.volume,
        'shuffle': s.shuffle,
        'repeat': s.repeat,
        'isPlaying': s.isPlaying,
      });

  Future<ResumeInfo?> getResumeActive() =>
      _ref.read(playbackClientProvider).getResumeActive();

  Future<ResumeInfo> getResumeForTrack(String trackId) =>
      _ref.read(playbackClientProvider).getResumeForTrack(trackId);
}

@riverpod
PlaybackRepository playbackRepository(PlaybackRepositoryRef ref) =>
    PlaybackRepository(ref);
