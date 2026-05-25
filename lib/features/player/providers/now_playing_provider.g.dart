// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_playing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nowPlayingHash() => r'7c7257b8b23393c24661125df019a2678ce26a65';

/// See also [nowPlaying].
@ProviderFor(nowPlaying)
final nowPlayingProvider = AutoDisposeStreamProvider<MediaItem?>.internal(
  nowPlaying,
  name: r'nowPlayingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nowPlayingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NowPlayingRef = AutoDisposeStreamProviderRef<MediaItem?>;
String _$playbackStateStreamHash() =>
    r'dedd13c308e8c6df0f83b20d0b15abd0b666e31e';

/// See also [playbackStateStream].
@ProviderFor(playbackStateStream)
final playbackStateStreamProvider =
    AutoDisposeStreamProvider<PlaybackState>.internal(
  playbackStateStream,
  name: r'playbackStateStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackStateStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaybackStateStreamRef = AutoDisposeStreamProviderRef<PlaybackState>;
String _$playbackQueueHash() => r'3fa23ad9b31958d60f74ce9087fc3ee817b782a6';

/// See also [playbackQueue].
@ProviderFor(playbackQueue)
final playbackQueueProvider =
    AutoDisposeStreamProvider<List<MediaItem>>.internal(
  playbackQueue,
  name: r'playbackQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaybackQueueRef = AutoDisposeStreamProviderRef<List<MediaItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
