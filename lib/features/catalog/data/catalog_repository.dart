import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/api/providers/catalog_client_provider.dart';
import 'package:harmonix_apps/core/models/lyrics.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  CatalogRepository(this._ref);

  final Ref _ref;

  Future<List<Track>> getTracks() async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    if (_ref.read(offlineModeProvider)) return library.allTracks();
    try {
      final tracks = await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTracks(),
      );
      await library.cacheCatalog(tracks);
      return library.allTracks();
    } catch (_) {
      final cached = await library.allTracks();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<Track> getTrack(String id) async {
    final library = await _ref.read(deviceLibraryProvider.future);
    final cached = (await library.allTracks()).where((track) => track.id == id);
    if ((id.startsWith('local:') || _ref.read(offlineModeProvider)) &&
        cached.isNotEmpty) {
      return cached.first;
    }
    try {
      return await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTrack(id),
      );
    } catch (_) {
      final cachedTrack = (await library.allTracks())
          .where((track) => track.id == id)
          .cast<Track?>()
          .firstWhere((track) => track != null, orElse: () => null);
      if (cachedTrack != null) return cachedTrack;
      rethrow;
    }
  }

  Future<List<Track>> search(String query) async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    final local = await library.search(query);
    if (_ref.read(offlineModeProvider)) return local;
    try {
      final List<Track> remote =
          await _ref.read(catalogClientProvider).search(query);
      return {
        for (final t in [...local, ...remote]) t.id: t
      }.values.toList();
    } catch (_) {
      return local;
    }
  }

  Future<TrackLyrics> getLyrics(String trackId) => _withTransientRetry(
        () => _ref.read(catalogClientProvider).getLyrics(trackId),
      );

  Future<List<Album>> getAlbums() async {
    final library = await _ref.read(deviceLibraryProvider.future);
    Future<List<Album>> cached() async =>
        (await library.store.all('albums')).map(Album.fromJson).toList();
    if (_ref.read(offlineModeProvider)) return cached();
    try {
      final albums = await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getAlbums(),
      );
      await library.store
          .replace('albums', {for (final a in albums) a.id: albumJson(a)});
      return albums;
    } catch (_) {
      final saved = await cached();
      if (saved.isNotEmpty) return saved;
      rethrow;
    }
  }

  Future<Album> getAlbum(String albumId) async {
    final library = await _ref.read(deviceLibraryProvider.future);
    final saved = await library.store.get('album_details', albumId);
    if (_ref.read(offlineModeProvider) && saved != null) {
      return Album.fromJson(saved);
    }
    try {
      final album = await _withTransientRetry<Album>(
        () => _ref.read(catalogClientProvider).getAlbum(albumId),
      );
      await library.store.put('album_details', albumId, albumJson(album));
      return album;
    } catch (_) {
      if (saved != null) return Album.fromJson(saved);
      rethrow;
    }
  }

  Future<T> _withTransientRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        if (!_isTransientHttpError(error) || attempt == maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    throw lastError ?? StateError('Unexpected retry failure');
  }

  bool _isTransientHttpError(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode ?? 0;
    return status == 502 || status == 503 || status == 504;
  }
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) =>
    CatalogRepository(ref);
