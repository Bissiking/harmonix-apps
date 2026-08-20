// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trackLyricsHash() => r'a6954708f38d9e00854186afba6ecf8675b56d71';

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

/// See also [trackLyrics].
@ProviderFor(trackLyrics)
const trackLyricsProvider = TrackLyricsFamily();

/// See also [trackLyrics].
class TrackLyricsFamily extends Family<AsyncValue<TrackLyrics>> {
  /// See also [trackLyrics].
  const TrackLyricsFamily();

  /// See also [trackLyrics].
  TrackLyricsProvider call(
    String trackId,
  ) {
    return TrackLyricsProvider(
      trackId,
    );
  }

  @override
  TrackLyricsProvider getProviderOverride(
    covariant TrackLyricsProvider provider,
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
  String? get name => r'trackLyricsProvider';
}

/// See also [trackLyrics].
class TrackLyricsProvider extends AutoDisposeFutureProvider<TrackLyrics> {
  /// See also [trackLyrics].
  TrackLyricsProvider(
    String trackId,
  ) : this._internal(
          (ref) => trackLyrics(
            ref as TrackLyricsRef,
            trackId,
          ),
          from: trackLyricsProvider,
          name: r'trackLyricsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$trackLyricsHash,
          dependencies: TrackLyricsFamily._dependencies,
          allTransitiveDependencies:
              TrackLyricsFamily._allTransitiveDependencies,
          trackId: trackId,
        );

  TrackLyricsProvider._internal(
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
    FutureOr<TrackLyrics> Function(TrackLyricsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrackLyricsProvider._internal(
        (ref) => create(ref as TrackLyricsRef),
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
  AutoDisposeFutureProviderElement<TrackLyrics> createElement() {
    return _TrackLyricsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackLyricsProvider && other.trackId == trackId;
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
mixin TrackLyricsRef on AutoDisposeFutureProviderRef<TrackLyrics> {
  /// The parameter `trackId` of this provider.
  String get trackId;
}

class _TrackLyricsProviderElement
    extends AutoDisposeFutureProviderElement<TrackLyrics> with TrackLyricsRef {
  _TrackLyricsProviderElement(super.provider);

  @override
  String get trackId => (origin as TrackLyricsProvider).trackId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
