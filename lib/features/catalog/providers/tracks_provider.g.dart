// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tracksHash() => r'58d20388d25d49327550f57fa3cef15f09a7e6a6';

/// See also [tracks].
@ProviderFor(tracks)
final tracksProvider = AutoDisposeFutureProvider<List<Track>>.internal(
  tracks,
  name: r'tracksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tracksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TracksRef = AutoDisposeFutureProviderRef<List<Track>>;
String _$trackDetailHash() => r'afe6385d3df0672b95cea59aeffd28d6baf8192d';

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

/// See also [trackDetail].
@ProviderFor(trackDetail)
const trackDetailProvider = TrackDetailFamily();

/// See also [trackDetail].
class TrackDetailFamily extends Family<AsyncValue<Track>> {
  /// See also [trackDetail].
  const TrackDetailFamily();

  /// See also [trackDetail].
  TrackDetailProvider call(
    String trackId,
  ) {
    return TrackDetailProvider(
      trackId,
    );
  }

  @override
  TrackDetailProvider getProviderOverride(
    covariant TrackDetailProvider provider,
  ) {
    return call(
      provider.trackId,
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
  String? get name => r'trackDetailProvider';
}

/// See also [trackDetail].
class TrackDetailProvider extends AutoDisposeFutureProvider<Track> {
  /// See also [trackDetail].
  TrackDetailProvider(
    String trackId,
  ) : this._internal(
          (ref) => trackDetail(
            ref as TrackDetailRef,
            trackId,
          ),
          from: trackDetailProvider,
          name: r'trackDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$trackDetailHash,
          dependencies: TrackDetailFamily._dependencies,
          allTransitiveDependencies:
              TrackDetailFamily._allTransitiveDependencies,
          trackId: trackId,
        );

  TrackDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.trackId,
  }) : super.internal();

  final String trackId;

  @override
  Override overrideWith(
    FutureOr<Track> Function(TrackDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrackDetailProvider._internal(
        (ref) => create(ref as TrackDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        trackId: trackId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Track> createElement() {
    return _TrackDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackDetailProvider && other.trackId == trackId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, trackId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TrackDetailRef on AutoDisposeFutureProviderRef<Track> {
  /// The parameter `trackId` of this provider.
  String get trackId;
}

class _TrackDetailProviderElement
    extends AutoDisposeFutureProviderElement<Track> with TrackDetailRef {
  _TrackDetailProviderElement(super.provider);

  @override
  String get trackId => (origin as TrackDetailProvider).trackId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
