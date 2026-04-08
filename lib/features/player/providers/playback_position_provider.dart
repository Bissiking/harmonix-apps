import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/audio/audio_handler_provider.dart';

part 'playback_position_provider.g.dart';

@riverpod
Stream<Duration> playbackPosition(PlaybackPositionRef ref) =>
    ref.watch(audioHandlerProvider).player.positionStream;
