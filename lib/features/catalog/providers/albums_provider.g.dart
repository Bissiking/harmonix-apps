// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'albums_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$albumsHash() => r'8482fa671db40df6a99b8fc9a967da795c81fff5';

/// See also [albums].
@ProviderFor(albums)
final albumsProvider = AutoDisposeFutureProvider<List<Album>>.internal(
  albums,
  name: r'albumsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$albumsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlbumsRef = AutoDisposeFutureProviderRef<List<Album>>;
String _$albumDetailHash() => r'020ad23ea53bfdad83fa3227651de7908e229c43';

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

/// See also [albumDetail].
@ProviderFor(albumDetail)
const albumDetailProvider = AlbumDetailFamily();

/// See also [albumDetail].
class AlbumDetailFamily extends Family<AsyncValue<Album>> {
  /// See also [albumDetail].
  const AlbumDetailFamily();

  /// See also [albumDetail].
  AlbumDetailProvider call(
    String albumId,
  ) {
    return AlbumDetailProvider(
      albumId,
    );
  }

  @override
  AlbumDetailProvider getProviderOverride(
    covariant AlbumDetailProvider provider,
  ) {
    return call(
      provider.albumId,
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
  String? get name => r'albumDetailProvider';
}

/// See also [albumDetail].
class AlbumDetailProvider extends AutoDisposeFutureProvider<Album> {
  /// See also [albumDetail].
  AlbumDetailProvider(
    String albumId,
  ) : this._internal(
          (ref) => albumDetail(
            ref as AlbumDetailRef,
            albumId,
          ),
          from: albumDetailProvider,
          name: r'albumDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$albumDetailHash,
          dependencies: AlbumDetailFamily._dependencies,
          allTransitiveDependencies:
              AlbumDetailFamily._allTransitiveDependencies,
          albumId: albumId,
        );

  AlbumDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.albumId,
  }) : super.internal();

  final String albumId;

  @override
  Override overrideWith(
    FutureOr<Album> Function(AlbumDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AlbumDetailProvider._internal(
        (ref) => create(ref as AlbumDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        albumId: albumId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Album> createElement() {
    return _AlbumDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AlbumDetailProvider && other.albumId == albumId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, albumId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AlbumDetailRef on AutoDisposeFutureProviderRef<Album> {
  /// The parameter `albumId` of this provider.
  String get albumId;
}

class _AlbumDetailProviderElement
    extends AutoDisposeFutureProviderElement<Album> with AlbumDetailRef {
  _AlbumDetailProviderElement(super.provider);

  @override
  String get albumId => (origin as AlbumDetailProvider).albumId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
