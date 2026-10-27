import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';

part 'now_playing_provider.g.dart';

@riverpod
Stream<MediaItem?> nowPlaying(NowPlayingRef ref) =>
    ref.watch(audioHandlerProvider).mediaItem;

@riverpod
Stream<PlaybackState> playbackStateStream(PlaybackStateStreamRef ref) =>
    ref.watch(audioHandlerProvider).playbackState;

@riverpod
Stream<List<MediaItem>> playbackQueue(PlaybackQueueRef ref) =>
    ref.watch(audioHandlerProvider).queue;

/// Live `(hasNext, hasPrevious)` of the local queue. The skip controls watch
/// it to disable themselves when the queue cannot advance — a lone title, for
/// instance — instead of silently doing nothing.
final playerNavigationProvider = StreamProvider<(bool, bool)>((ref) {
  final navigation = ref.watch(audioHandlerProvider).navigation;
  // Buffer the initial value until Riverpod subscribes to the returned stream.
  final controller = StreamController<(bool, bool)>();
  void emit() => controller.add(navigation.value);
  navigation.addListener(emit);
  ref.onDispose(() {
    navigation.removeListener(emit);
    controller.close();
  });
  emit();
  return controller.stream;
});
