import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/data/catalog_repository.dart';
import '../audio/audio_handler_provider.dart';
import '../models/track.dart';
import '../settings/settings_repository.dart';
import '../utils/image_url_builder.dart';
import 'platform_channel.dart';

/// Registers the Flutter-side handler for Android Auto MethodChannel calls.
///
/// Call [AutoBridge.register] once after ProviderScope is initialized.
class AutoBridge {
  AutoBridge._();

  static StreamSubscription<MediaItem?>? _mediaItemSub;
  static StreamSubscription<PlaybackState>? _playbackStateSub;

  static void register(WidgetRef ref) {
    harmonixAutoChannel.setMethodCallHandler(
      (call) => _handleCall(call, ref),
    );
    _registerStateSync(ref);
  }

  static Future<dynamic> _handleCall(MethodCall call, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers =
        token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null;

    switch (call.method) {
      case 'getQueue':
        final queueItems = _queueToAutoItems(handler.queue.value, baseUrl);
        if (queueItems.isNotEmpty) return queueItems;

        try {
          final tracks = await ref.read(catalogRepositoryProvider).getTracks();
          return _tracksToAutoItems(tracks, baseUrl);
        } catch (_) {
          return queueItems;
        }

      case 'playFromId':
        final trackId = call.arguments as String;
        try {
          final tracks = await ref.read(catalogRepositoryProvider).getTracks();
          final initialIndex = tracks.indexWhere((track) => track.id == trackId);
          if (tracks.isNotEmpty && initialIndex >= 0) {
            final items = tracks.map((track) => _trackToMediaItem(baseUrl, track)).toList();
            final urls = tracks.map((track) => _trackStreamUrl(baseUrl, track)).toList();
            await handler.loadQueue(
              items,
              urls,
              initialIndex: initialIndex,
              headers: headers,
            );
            await handler.play();
            return null;
          }
        } catch (_) {
          // Fall back to single-track playback below when catalog is unavailable.
        }

        final trackStreamUrl = streamUrl(baseUrl, trackId);
        final mediaItem = await _findMediaItemForTrackId(ref, baseUrl, trackId);
        await handler.playFromTrackId(
          trackId,
          trackStreamUrl,
          initialMediaItem: mediaItem,
          headers: headers,
        );

      case 'play':
        await handler.play();

      case 'pause':
        await handler.pause();

      case 'skipToNext':
        await handler.skipToNext();

      case 'skipToPrevious':
        await handler.skipToPrevious();

      case 'seekTo':
        final positionMs = call.arguments as int;
        await handler.seek(Duration(milliseconds: positionMs));

      case 'stop':
        await handler.stop();

      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  static List<Map<String, dynamic>> _queueToAutoItems(
    List<dynamic> queue,
    String baseUrl,
  ) {
    return queue.map((item) {
      final track = item as dynamic;
      return <String, dynamic>{
        'id': track.id,
        'title': track.title,
        'subtitle': track.artist,
        'coverUrl': track.extras?['coverFile'] != null
            ? coverUrl(baseUrl, track.extras!['coverFile'] as String)
            : null,
        'playable': true,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _tracksToAutoItems(
    List<Track> tracks,
    String baseUrl,
  ) {
    return tracks
        .map((track) => <String, dynamic>{
              'id': track.id,
              'title': track.title,
              'subtitle': track.artist,
              'coverUrl': track.coverFile != null
                  ? coverUrl(baseUrl, track.coverFile!)
                  : (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                      ? coverUrl(baseUrl, track.coverUrl!)
                      : null,
              'playable': true,
            })
        .toList();
  }

  static void _registerStateSync(WidgetRef ref) {
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();

    final handler = ref.read(audioHandlerProvider);

    _mediaItemSub = handler.mediaItem.listen((item) async {
      if (item == null) return;
      try {
        await harmonixAutoChannel.invokeMethod('nowPlayingChanged', {
          'id': item.id,
          'title': item.title,
          'subtitle': item.artist ?? '',
          'album': item.album ?? '',
          'artUri': item.artUri?.toString(),
          'durationMs': item.duration?.inMilliseconds,
        });
      } on MissingPluginException {
        // Ignore when not running under Android Auto host.
      }
    });

    _playbackStateSub = handler.playbackState.listen((state) async {
      try {
        await harmonixAutoChannel.invokeMethod('playbackStateChanged', {
          'playing': state.playing,
          'processingState': _processingStateToInt(state.processingState),
          'positionMs': state.updatePosition.inMilliseconds,
          'speed': state.speed,
        });
      } on MissingPluginException {
        // Ignore when not running under Android Auto host.
      }
    });
  }

  static int _processingStateToInt(AudioProcessingState state) {
    return switch (state) {
      AudioProcessingState.idle => 0,
      AudioProcessingState.loading => 1,
      AudioProcessingState.buffering => 2,
      AudioProcessingState.ready => 3,
      AudioProcessingState.completed => 4,
      AudioProcessingState.error => 5,
    };
  }

  static Future<MediaItem?> _findMediaItemForTrackId(
    WidgetRef ref,
    String baseUrl,
    String trackId,
  ) async {
    final queue = ref.read(audioHandlerProvider).queue.value;
    for (final item in queue) {
      if (item.id == trackId) return item;
    }

    try {
      final track = await ref.read(catalogRepositoryProvider).getTrack(trackId);
      return _trackToMediaItem(baseUrl, track);
    } catch (_) {
      return null;
    }
  }

  static MediaItem _trackToMediaItem(String baseUrl, Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      artUri: track.coverFile != null
          ? Uri.tryParse(coverUrl(baseUrl, track.coverFile!))
          : (track.coverUrl != null && track.coverUrl!.isNotEmpty)
              ? Uri.tryParse(coverUrl(baseUrl, track.coverUrl!))
              : null,
      duration: Duration(milliseconds: track.durationMs),
      extras: {'coverFile': track.coverFile},
    );
  }

  static String _trackStreamUrl(String baseUrl, Track track) {
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
}

/// Sends the current queue/state to the Android Auto layer when it changes.
Future<void> notifyAutoQueueChanged(List<Track> tracks, String baseUrl) async {
  try {
    final items = tracks.map((t) => <String, dynamic>{
          'id': t.id,
          'title': t.title,
          'subtitle': t.artist,
          'coverUrl': t.coverFile != null
              ? coverUrl(baseUrl, t.coverFile!)
              : null,
          'playable': true,
        }).toList();
    await harmonixAutoChannel.invokeMethod('queueChanged', items);
  } on MissingPluginException {
    // Not running under Android Auto — ignore
  }
}
