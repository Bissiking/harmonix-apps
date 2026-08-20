import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/providers/playlist_client_provider.dart';
import 'package:harmonix_apps/core/models/playlist.dart';

part 'playlists_repository.g.dart';

class PlaylistsRepository {
  PlaylistsRepository(this._ref);

  final dynamic _ref;

  Future<List<Playlist>> getPlaylists() => _withTransientRetry(
        () => _ref.read(playlistClientProvider).getPlaylists(),
      );

  Future<Playlist> getPlaylist(String id) => _withTransientRetry(
        () => _ref.read(playlistClientProvider).getPlaylist(id),
      );

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
        () => _ref.read(playlistClientProvider).addTracks(id, {
          'track_ids': trackIds,
        }),
      );

  Future<void> removeTrack(String id, String trackId) =>
      _withTransientRetry(
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