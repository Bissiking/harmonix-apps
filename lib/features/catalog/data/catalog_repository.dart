import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/api/providers/catalog_client_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  CatalogRepository(this._ref);

  final dynamic _ref;
  List<Track>? _lastTracksCache;

  Future<List<Track>> getTracks() async {
    try {
      final tracks = await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTracks(),
      );
      _lastTracksCache = tracks;
      return tracks;
    } catch (_) {
      final cached = _lastTracksCache;
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<Track> getTrack(String id) async {
    try {
      return await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTrack(id),
      );
    } catch (_) {
      final cachedTrack = _lastTracksCache
          ?.where((track) => track.id == id)
          .cast<Track?>()
          .firstWhere((track) => track != null, orElse: () => null);
      if (cachedTrack != null) return cachedTrack;
      rethrow;
    }
  }

  Future<List<Track>> search(String query) =>
      _withTransientRetry(() => _ref.read(catalogClientProvider).search(query));

  Future<List<Album>> getAlbums() async {
    final tracks = await getTracks();
    return _buildAlbumsFromTracks(tracks);
  }

  Future<Album> getAlbum(String albumId) async {
    final albums = await getAlbums();
    final album = albums.where((a) => a.id == albumId).cast<Album?>().firstWhere(
          (a) => a != null,
          orElse: () => null,
        );
    if (album != null) return album;
    throw StateError('Album not found: $albumId');
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

  List<Album> _buildAlbumsFromTracks(List<Track> tracks) {
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      final rawAlbum = track.album?.trim();
      final albumTitle =
          rawAlbum != null && rawAlbum.isNotEmpty ? rawAlbum : 'Single';
      grouped.putIfAbsent(albumTitle, () => <Track>[]).add(track);
    }

    final albums = grouped.entries.map((entry) {
      final albumTracks = entry.value;
      final first = albumTracks.first;
      final artist = first.artist.isNotEmpty ? first.artist : 'Unknown artist';
      final totalDurationMs = albumTracks.fold<int>(
        0,
        (sum, track) => sum + track.durationMs,
      );
      return Album(
        id: _albumIdFromTitleAndArtist(entry.key, artist),
        title: entry.key,
        artist: artist,
        coverFile: first.coverFile,
        coverUrl: first.coverUrl,
        tracks: albumTracks,
        totalDurationMs: totalDurationMs,
      );
    }).toList();

    albums.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return albums;
  }

  String _albumIdFromTitleAndArtist(String title, String artist) {
    final key = '$title-$artist'.toLowerCase();
    return key
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) =>
    CatalogRepository(ref);
