import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/library_client_provider.dart';
import '../../../core/models/track.dart';

part 'library_repository.g.dart';

class LibraryRepository {
  LibraryRepository(this._ref);

  final dynamic _ref;

  Future<List<Track>> getFavorites() {
    assert(() {
      debugPrint('LibraryRepository.getFavorites');
      return true;
    }());
    return _ref.read(libraryClientProvider).getFavorites();
  }

  Future<void> toggleFavorite(String trackId) {
    assert(() {
      debugPrint('LibraryRepository.toggleFavorite trackId=$trackId');
      return true;
    }());
    return _ref.read(libraryClientProvider).toggleFavorite({'trackId': trackId});
  }
}

@riverpod
LibraryRepository libraryRepository(LibraryRepositoryRef ref) =>
    LibraryRepository(ref);
