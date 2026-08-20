import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/playlist.dart';
import 'package:harmonix_apps/features/library/data/playlists_repository.dart';

part 'playlists_provider.g.dart';

@riverpod
Future<List<Playlist>> playlists(PlaylistsRef ref) =>
    ref.watch(playlistsRepositoryProvider).getPlaylists();

@riverpod
Future<Playlist> playlistDetail(PlaylistDetailRef ref, String playlistId) =>
    ref.watch(playlistsRepositoryProvider).getPlaylist(playlistId);

@riverpod
class PlaylistsActions extends _$PlaylistsActions {
  @override
  FutureOr<void> build() {}

  Future<Playlist> create(String name, {String? description}) async {
    final playlist = await ref
        .read(playlistsRepositoryProvider)
        .createPlaylist(name, description: description);
    ref.invalidate(playlistsProvider);
    return playlist;
  }

  Future<void> rename(String id, String name) async {
    await ref.read(playlistsRepositoryProvider).renamePlaylist(id, name);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistDetailProvider(id));
  }

  Future<void> delete(String id) async {
    await ref.read(playlistsRepositoryProvider).deletePlaylist(id);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistDetailProvider(id));
  }

  Future<void> addTracks(String id, List<String> trackIds) async {
    await ref.read(playlistsRepositoryProvider).addTracks(id, trackIds);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistDetailProvider(id));
  }

  Future<void> removeTrack(String id, String trackId) async {
    await ref.read(playlistsRepositoryProvider).removeTrack(id, trackId);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistDetailProvider(id));
  }
}