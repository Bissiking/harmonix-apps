import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/audio/audio_handler.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';
import 'package:harmonix_apps/core/utils/stream_url_resolver.dart';

part 'player_provider.g.dart';

int _webQueueGeneration = 0;
StreamSubscription<dynamic>? _webQueueSub;

@riverpod
class Player extends _$Player {
  @override
  void build() {}

  Future<void> playTrack(Track track) async {
    _webQueueGeneration++;
    await _webQueueSub?.cancel();
    _webQueueSub = null;
    final handler = ref.read(audioHandlerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;
    final url = _resolveStreamUrl(baseUrl, track);
    final dio = ref.read(dioProvider);
    final resolved = await resolvePlayableStreamUrl(
      url: url,
      headers: headers,
      dio: dio,
    );

    assert(() {
      debugPrint(
        'playTrack: id=${track.id} url=${resolved.url} '
        'hasAuth=${token != null}',
      );
      return true;
    }());

    final mediaItem = _mediaItemFromTrack(baseUrl, track);

    await handler.playFromTrackId(
      track.id,
      resolved.url,
      initialMediaItem: mediaItem,
      headers: resolved.headers,
    );
  }

  Future<void> playFromQueue(List<Track> tracks, int index) async {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;

    final handler = ref.read(audioHandlerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;
    final dio = ref.read(dioProvider);

    if (!kIsWeb) {
      final items =
          tracks.map((track) => _mediaItemFromTrack(baseUrl, track)).toList();
      final urls =
          tracks.map((track) => _resolveStreamUrl(baseUrl, track)).toList();

      await handler.loadQueue(
        items,
        urls,
        initialIndex: index,
        headers: headers,
      );
      await handler.play();
      return;
    }

    _webQueueGeneration++;
    final generation = _webQueueGeneration;
    await _webQueueSub?.cancel();
    _webQueueSub = null;

    final rotated = [
      ...tracks.sublist(index),
      ...tracks.sublist(0, index),
    ];
    final items =
        rotated.map((track) => _mediaItemFromTrack(baseUrl, track)).toList();
    final urls =
        rotated.map((track) => _resolveStreamUrl(baseUrl, track)).toList();

    final initial = await resolvePlayableStreamUrl(
      url: urls[0],
      headers: headers,
      dio: dio,
    );
    if (generation != _webQueueGeneration) return;

    await handler.loadQueueIncremental(items, initial.url, initialIndex: 0);
    await handler.play();

    _webQueueSub = _maintainWebQueueWindow(
      generation: generation,
      handler: handler,
      items: items,
      urls: urls,
      headers: headers,
      dio: dio,
      initialBlobUrl: initial.url,
    );
  }

  StreamSubscription<dynamic> _maintainWebQueueWindow({
    required int generation,
    required HarmonixAudioHandler handler,
    required List<MediaItem> items,
    required List<String> urls,
    required Map<String, String>? headers,
    required Dio dio,
    required String initialBlobUrl,
  }) {
    const window = 12;
    const keepBehind = 6;
    var target = window + 1;
    var maxResolved = 1;
    final blobUrls = <int, String>{0: initialBlobUrl};

    late StreamSubscription<dynamic> sub;
    sub = handler.player.currentIndexStream.listen((index) async {
      if (generation != _webQueueGeneration) {
        await sub.cancel();
        return;
      }
      final current = index ?? 0;
      final nextTarget = current + window + 1;
      if (nextTarget > target) target = nextTarget;

      final revokeBefore = current - keepBehind;
      for (final entry in blobUrls.entries.toList()) {
        if (entry.key < revokeBefore) {
          revokeBlobUrl(entry.value);
          blobUrls.remove(entry.key);
        }
      }
    });

    Future<void> resolverLoop() async {
      while (generation == _webQueueGeneration) {
        if (maxResolved >= urls.length) return;
        if (maxResolved < target) {
          final i = maxResolved++;
          try {
            final resolved = await resolvePlayableStreamUrl(
              url: urls[i],
              headers: headers,
              dio: dio,
            );
            if (generation != _webQueueGeneration) return;
            await handler.appendQueueItem(resolved.url, items[i]);
            blobUrls[i] = resolved.url;
          } catch (_) {
            // Skip unresolvable tracks; the queue stays playable.
          }
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }
    }
    unawaited(resolverLoop());

    return sub;
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
        extras: {
          'coverFile': track.coverFile,
          'coverUrl': track.coverUrl,
        },
      );

  Future<void> play() => ref.read(audioHandlerProvider).play();
  Future<void> pause() => ref.read(audioHandlerProvider).pause();
  Future<void> skipToNext() => ref.read(audioHandlerProvider).skipToNext();
  Future<void> skipToPrevious() =>
      ref.read(audioHandlerProvider).skipToPrevious();
  Future<void> seek(Duration position) =>
      ref.read(audioHandlerProvider).seek(position);

  Future<void> setRepeat(AudioServiceRepeatMode mode) =>
      ref.read(audioHandlerProvider).setRepeatMode(mode);

  Future<void> setShuffle(bool enabled) =>
      ref.read(audioHandlerProvider).setShuffleMode(
            enabled
                ? AudioServiceShuffleMode.all
                : AudioServiceShuffleMode.none,
          );
}
