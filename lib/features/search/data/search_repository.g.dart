// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchTracksHash() => r'af3f4daad78570935fb42d50f3f634913028ea02';

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

/// See also [searchTracks].
@ProviderFor(searchTracks)
const searchTracksProvider = SearchTracksFamily();

/// See also [searchTracks].
class SearchTracksFamily extends Family<AsyncValue<List<Track>>> {
  /// See also [searchTracks].
  const SearchTracksFamily();

  /// See also [searchTracks].
  SearchTracksProvider call(
    String query,
  ) {
    return SearchTracksProvider(
      query,
    );
  }

  @override
  SearchTracksProvider getProviderOverride(
    covariant SearchTracksProvider provider,
  ) {
    return call(
      provider.query,
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
  String? get name => r'searchTracksProvider';
}

/// See also [searchTracks].
class SearchTracksProvider extends AutoDisposeFutureProvider<List<Track>> {
  /// See also [searchTracks].
  SearchTracksProvider(
    String query,
  ) : this._internal(
          (ref) => searchTracks(
            ref as SearchTracksRef,
            query,
          ),
          from: searchTracksProvider,
          name: r'searchTracksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchTracksHash,
          dependencies: SearchTracksFamily._dependencies,
          allTransitiveDependencies:
              SearchTracksFamily._allTransitiveDependencies,
          query: query,
        );

  SearchTracksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Track>> Function(SearchTracksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchTracksProvider._internal(
        (ref) => create(ref as SearchTracksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Track>> createElement() {
    return _SearchTracksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchTracksProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchTracksRef on AutoDisposeFutureProviderRef<List<Track>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchTracksProviderElement
    extends AutoDisposeFutureProviderElement<List<Track>> with SearchTracksRef {
  _SearchTracksProviderElement(super.provider);

  @override
  String get query => (origin as SearchTracksProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
