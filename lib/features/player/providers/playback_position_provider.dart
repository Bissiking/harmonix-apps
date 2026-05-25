import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';

part 'playback_position_provider.g.dart';

@riverpod
Stream<Duration> playbackPosition(PlaybackPositionRef ref) =>
    ref.watch(audioHandlerProvider).player.positionStream;

final playbackDurationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioHandlerProvider).player.durationStream;
});
