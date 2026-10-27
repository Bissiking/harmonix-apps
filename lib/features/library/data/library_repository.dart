import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/providers/library_client_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

part 'library_repository.g.dart';

class LibraryRepository {
  LibraryRepository(this._ref);

  final Ref _ref;

  Future<List<Track>> getFavorites() async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    Future<List<Track>> cached() async =>
        (await library.store.all('favorites')).map(Track.fromJson).toList();
    if (_ref.read(offlineModeProvider)) return cached();
    assert(() {
      debugPrint('LibraryRepository.getFavorites');
      return true;
    }());
    try {
      final List<Track> remote =
          await _ref.read(libraryClientProvider).getFavorites();
      final personal = (await cached()).where((t) => t.id.startsWith('local:'));
      final tracks = [...remote, ...personal];
      await library.store
          .replace('favorites', {for (final t in tracks) t.id: t.toJson()});
      return tracks;
    } catch (_) {
      return cached();
    }
  }

  Future<void> toggleFavorite(String trackId) async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    final saved = await library.store.get('favorites', trackId);
    if (trackId.startsWith('local:')) {
      if (saved != null) {
        await library.store.remove('favorites', trackId);
      } else {
        final track =
            (await library.allTracks()).firstWhere((t) => t.id == trackId);
        await library.store.put(
            'favorites', trackId, track.copyWith(isFavorite: true).toJson());
      }
      return;
    }
    if (_ref.read(offlineModeProvider)) {
      throw StateError('Les favoris Sonora se modifient après reconnexion.');
    }
    assert(() {
      debugPrint('LibraryRepository.toggleFavorite trackId=$trackId');
      return true;
    }());
    await _ref.read(libraryClientProvider).toggleFavorite({'trackId': trackId});
    if (saved != null) {
      await library.store.remove('favorites', trackId);
    } else {
      final track =
          (await library.allTracks()).firstWhere((t) => t.id == trackId);
      await library.store
          .put('favorites', trackId, track.copyWith(isFavorite: true).toJson());
    }
  }
}

@riverpod
LibraryRepository libraryRepository(LibraryRepositoryRef ref) =>
    LibraryRepository(ref);
