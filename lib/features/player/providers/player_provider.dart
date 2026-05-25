import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  @override
  void build() {}

  Future<void> playTrack(Track track) async {
    final handler = ref.read(audioHandlerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers =
        token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null;
    final url = _resolveStreamUrl(baseUrl, track);

    assert(() {
      debugPrint('playTrack: id=${track.id} url=$url hasAuth=${token != null}');
      return true;
    }());

    final mediaItem = _mediaItemFromTrack(baseUrl, track);

    await handler.playFromTrackId(
      track.id,
      url,
      initialMediaItem: mediaItem,
      headers: headers,
    );
  }

  Future<void> playFromQueue(List<Track> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;

    final handler = ref.read(audioHandlerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers =
        token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null;

    final items = tracks.map((track) => _mediaItemFromTrack(baseUrl, track)).toList();
    final urls = tracks.map((track) => _resolveStreamUrl(baseUrl, track)).toList();

    await handler.loadQueue(
      items,
      urls,
      initialIndex: index,
      headers: headers,
    );
    await handler.play();
  }

  String _resolveStreamUrl(String baseUrl, Track track) {
    final raw = track.streamUrl;
    if (raw == null || raw.isEmpty) {
      return streamUrl(baseUrl, track.id);
    }

    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final host = uri.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return streamUrl(baseUrl, track.id);
      }
    }

    return streamUrl(baseUrl, raw);
  }

  MediaItem _mediaItemFromTrack(String baseUrl, Track track) => MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        artUri: track.coverFile != null
            ? Uri.parse(coverUrl(baseUrl, track.coverFile!))
            : (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                ? Uri.parse(coverUrl(baseUrl, track.coverUrl!))
                : null,
        duration: Duration(milliseconds: track.durationMs),
        extras: {'coverFile': track.coverFile},
      );

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
