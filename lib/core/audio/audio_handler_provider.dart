import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/audio/audio_handler.dart';

part 'audio_handler_provider.g.dart';

/// Overridden in main.dart after AudioService.init() completes.
@Riverpod(keepAlive: true)
HarmonixAudioHandler audioHandler(AudioHandlerRef ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
}
