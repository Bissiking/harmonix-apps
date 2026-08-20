// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playlistsHash() => r'6342edd2af043d11f75d7fc37007e047fbda426a';

/// See also [playlists].
@ProviderFor(playlists)
final playlistsProvider = AutoDisposeFutureProvider<List<Playlist>>.internal(
  playlists,
  name: r'playlistsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playlistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaylistsRef = AutoDisposeFutureProviderRef<List<Playlist>>;
String _$playlistDetailHash() => r'557926f3c2fb0dee3a283ff114b80f9ecf6d481a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [playlistDetail].
@ProviderFor(playlistDetail)
const playlistDetailProvider = PlaylistDetailFamily();

/// See also [playlistDetail].
class PlaylistDetailFamily extends Family<AsyncValue<Playlist>> {
  /// See also [playlistDetail].
  const PlaylistDetailFamily();

  /// See also [playlistDetail].
  PlaylistDetailProvider call(
    String playlistId,
  ) {
    return PlaylistDetailProvider(
      playlistId,
    );
  }

  @override
  PlaylistDetailProvider getProviderOverride(
    covariant PlaylistDetailProvider provider,
  ) {
    return call(
      provider.playlistId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'playlistDetailProvider';
}

/// See also [playlistDetail].
class PlaylistDetailProvider extends AutoDisposeFutureProvider<Playlist> {
  /// See also [playlistDetail].
  PlaylistDetailProvider(
    String playlistId,
  ) : this._internal(
          (ref) => playlistDetail(
            ref as PlaylistDetailRef,
            playlistId,
          ),
          from: playlistDetailProvider,
          name: r'playlistDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$playlistDetailHash,
          dependencies: PlaylistDetailFamily._dependencies,
          allTransitiveDependencies:
              PlaylistDetailFamily._allTransitiveDependencies,
          playlistId: playlistId,
        );

  PlaylistDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.playlistId,
  }) : super.internal();

  final String playlistId;

  @override
  Override overrideWith(
    FutureOr<Playlist> Function(PlaylistDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlaylistDetailProvider._internal(
        (ref) => create(ref as PlaylistDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        playlistId: playlistId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Playlist> createElement() {
    return _PlaylistDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistDetailProvider && other.playlistId == playlistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, playlistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PlaylistDetailRef on AutoDisposeFutureProviderRef<Playlist> {
  /// The parameter `playlistId` of this provider.
  String get playlistId;
}

class _PlaylistDetailProviderElement
    extends AutoDisposeFutureProviderElement<Playlist> with PlaylistDetailRef {
  _PlaylistDetailProviderElement(super.provider);

  @override
  String get playlistId => (origin as PlaylistDetailProvider).playlistId;
}

String _$playlistsActionsHash() => r'7b1e3aec05f4b2549a01cde3325148a6e7cacb75';

/// See also [PlaylistsActions].
@ProviderFor(PlaylistsActions)
final playlistsActionsProvider =
    AutoDisposeAsyncNotifierProvider<PlaylistsActions, void>.internal(
  PlaylistsActions.new,
  name: r'playlistsActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playlistsActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlaylistsActions = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
