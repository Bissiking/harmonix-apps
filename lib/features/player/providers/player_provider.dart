import 'package:audio_service/audio_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/audio/audio_handler_provider.dart';
import '../../../core/models/track.dart';
import '../../../core/settings/settings_repository.dart';
import '../../../core/utils/image_url_builder.dart';

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  @override
  void build() {}

  Future<void> playTrack(Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final baseUrl = ref.read(settingsRepositoryProvider).serverUrl;
    final url = streamUrl(baseUrl, track.id);

    final mediaItem = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.coverFile != null
          ? Uri.parse(coverUrl(baseUrl, track.coverFile!))
          : null,
      duration: Duration(milliseconds: track.durationMs),
      extras: {'coverFile': track.coverFile},
    );

    await handler.playFromTrackId(track.id, url, mediaItem: mediaItem);
  }

  Future<void> play() => ref.read(audioHandlerProvider).play();
  Future<void> pause() => ref.read(audioHandlerProvider).pause();
  Future<void> skipToNext() => ref.read(audioHandlerProvider).skipToNext();
  Future<void> skipToPrevious() => ref.read(audioHandlerProvider).skipToPrevious();
  Future<void> seek(Duration position) => ref.read(audioHandlerProvider).seek(position);

  Future<void> setRepeat(AudioServiceRepeatMode mode) =>
      ref.read(audioHandlerProvider).setRepeatMode(mode);

  Future<void> setShuffle(bool enabled) =>
      ref.read(audioHandlerProvider).setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      );
}
