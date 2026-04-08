import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_handler.dart';
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

  static void register(WidgetRef ref) {
    harmonixAutoChannel.setMethodCallHandler(
      (call) => _handleCall(call, ref),
    );
  }

  static Future<dynamic> _handleCall(MethodCall call, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final baseUrl = ref.read(settingsRepositoryProvider).serverUrl;

    switch (call.method) {
      case 'getQueue':
        return _queueToAutoItems(handler.queue.value, baseUrl);

      case 'playFromId':
        final trackId = call.arguments as String;
        final streamUrl = streamUrl(baseUrl, trackId);
        await handler.playFromTrackId(trackId, streamUrl);

      case 'play':
        await handler.play();

      case 'pause':
        await handler.pause();

      case 'skipToNext':
        await handler.skipToNext();

      case 'skipToPrevious':
        await handler.skipToPrevious();

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
