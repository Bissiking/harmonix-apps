import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';

/// Registers keyboard media-key handlers for desktop platforms.
/// Call once from a top-level widget using ref.
void registerDesktopMediaKeys(WidgetRef ref) {
  if (!_isDesktop) return;

  HardwareKeyboard.instance.addHandler((event) {
    if (event is! KeyDownEvent) return false;

    final handler = ref.read(audioHandlerProvider);
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.mediaPlayPause) {
      final playing = handler.playbackState.value.playing;
      playing ? handler.pause() : handler.play();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      handler.skipToNext();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      handler.skipToPrevious();
      return true;
    }
    return false;
  });
}

bool get _isDesktop =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux;
