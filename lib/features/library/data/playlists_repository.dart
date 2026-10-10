import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/providers/playlist_client_provider.dart';
import 'package:harmonix_apps/core/models/playlist.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

part 'playlists_repository.g.dart';

class PlaylistsRepository {
  PlaylistsRepository(this._ref);

  final Ref _ref;

  Future<List<Playlist>> getPlaylists() async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    Future<List<Playlist>> cached() async =>
        (await library.store.all('sonora_playlists'))
            .map(Playlist.fromJson)
            .toList();
    if (_ref.read(offlineModeProvider)) return cached();
    try {
      final List<Playlist> playlists =
          await _ref.read(playlistClientProvider).getPlaylists();
      await library.store.replace('sonora_playlists',
          {for (final p in playlists) p.id: playlistJson(p)});
      return playlists;
    } catch (_) {
      return cached();
    }
  }

  Future<Playlist> getPlaylist(String id) async {
    final DeviceLibrary library = await _ref.read(deviceLibraryProvider.future);
    final saved = await library.store.get('sonora_playlist_details', id);
    if (_ref.read(offlineModeProvider)) {
      if (saved == null) {
        throw StateError(
            'Ouvre cette playlist une fois en ligne pour la mémoriser.');
      }
      return Playlist.fromJson(saved);
    }
    try {
      final Playlist playlist =
          await _ref.read(playlistClientProvider).getPlaylist(id);
      await library.store
          .put('sonora_playlist_details', id, playlistJson(playlist));
      return playlist;
    } catch (_) {
      if (saved != null) return Playlist.fromJson(saved);
      rethrow;
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description}) =>
      _withTransientRetry(
        () => _ref.read(playlistClientProvider).createPlaylist({
          'name': name,
          if (description != null && description.trim().isNotEmpty)
            'description': description,
        }),
      );

  Future<Playlist> renamePlaylist(String id, String name) =>
      _withTransientRetry(
        () => _ref.read(playlistClientProvider).renamePlaylist(id, {
          'name': name,
        }),
      );

  Future<void> deletePlaylist(String id) => _withTransientRetry(
        () => _ref.read(playlistClientProvider).deletePlaylist(id),
      );

  Future<void> addTracks(String id, List<String> trackIds) =>
      _withTransientRetry(
        () {
          if (trackIds.any((id) => id.startsWith('local:'))) {
            throw StateError(
                'Utilise une playlist mixte pour les fichiers personnels.');
          }
          return _ref.read(playlistClientProvider).addTracks(id, {
            'track_ids': trackIds,
          });
        },
      );

  Future<void> removeTrack(String id, String trackId) => _withTransientRetry(
        () => _ref.read(playlistClientProvider).removeTrack(id, trackId),
      );

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
PlaylistsRepository playlistsRepository(PlaylistsRepositoryRef ref) =>
    PlaylistsRepository(ref);
