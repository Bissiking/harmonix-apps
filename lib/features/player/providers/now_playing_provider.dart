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
