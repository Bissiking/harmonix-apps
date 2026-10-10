// device_library.dart
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';

class DeviceLibrary {
  DeviceLibrary(this.store);
  final LocalStore store;
  Future<List<DeviceTrack>> files() async =>
      (await store.all('files')).map(DeviceTrack.fromJson).toList();
  Future<DeviceTrack?> file(String id) async {
    final data = await store.get('files', id);
    return data == null ? null : DeviceTrack.fromJson(data);
  }

  Future<void> saveFile(DeviceTrack file) =>
      store.put('files', file.track.id, file.toJson());
  Future<List<Track>> catalog() async =>
      (await store.all('catalog')).map(Track.fromJson).toList();
  Future<void> cacheCatalog(List<Track> tracks) =>
      store.replace('catalog', {for (final t in tracks) t.id: t.toJson()});
  Future<List<Track>> allTracks() async {
    final tracks = {for (final track in await catalog()) track.id: track};
    for (final file in await files()) {
      // Downloads retain their audio, but current catalogue metadata wins.
      // Otherwise an old download would mask a Studio Night tag update.
      if (file.source == MusicSource.personal ||
          !tracks.containsKey(file.track.id)) {
        tracks[file.track.id] = file.track;
      }
    }
    return tracks.values.toList();
  }

  Future<List<Track>> search(String query) async {
    final q = query.toLowerCase().trim();
    return (await allTracks())
        .where((t) =>
            '${t.title} ${t.artist} ${t.album ?? ""}'.toLowerCase().contains(q))
        .toList();
  }

  Future<List<MixedPlaylist>> playlists() async =>
      (await store.all('mixed_playlists')).map(MixedPlaylist.fromJson).toList();
  Future<void> savePlaylist(MixedPlaylist playlist, {int? baseRevision}) async {
    // The revision check and write must share a transaction.
    await (store.database as Database).transaction((txn) async {
      final scoped = LocalStore(txn, store.scope);
      final data = await scoped.get('mixed_playlists', playlist.id);
      if (data != null && baseRevision != null) {
        applyPlaylistEdit(MixedPlaylist.fromJson(data), playlist, baseRevision);
      }
      await scoped.put('mixed_playlists', playlist.id, playlist.toJson());
    });
  }

  Future<MixedPlaylist> createPlaylist(String name) async {
    final random = Random.secure();
    final id = List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final playlist = MixedPlaylist(id: 'device:$id', name: name.trim());
    if (playlist.name.isEmpty) throw ArgumentError('Playlist name is empty');
    await savePlaylist(playlist);
    return playlist;
  }
}

final deviceLibraryProvider = FutureProvider<DeviceLibrary>(
    (ref) async => DeviceLibrary(await ref.watch(localStoreProvider.future)));
final deviceTracksProvider = FutureProvider<List<DeviceTrack>>(
    (ref) async => (await ref.watch(deviceLibraryProvider.future)).files());
final mixedPlaylistsProvider = FutureProvider<List<MixedPlaylist>>(
    (ref) async => (await ref.watch(deviceLibraryProvider.future)).playlists());
final libraryRevisionProvider = StateProvider<int>((ref) => 0);
final offlineModeProvider = StateNotifierProvider<OfflineModeController, bool>(
    (ref) => OfflineModeController(ref.watch(settingsRepositoryProvider)));

class OfflineModeController extends StateNotifier<bool> {
  OfflineModeController(this.settings) : super(settings.offlineMode);
  final SettingsRepository settings;
  Future<void> setEnabled(bool value) async {
    await settings.setOfflineMode(value);
    state = value;
  }
}

enum TransferStatus { running, paused, failed, completed, cancelled }

class Transfer {
  const Transfer(this.track, this.status,
      {this.received = 0, this.total = 0, this.error});
  final Track track;
  final TransferStatus status;
  final int received;
  final int total;
  final String? error;
}

final transfersProvider =
    StateNotifierProvider<DownloadsController, Map<String, Transfer>>((ref) {
  ref.watch(libraryScopeProvider);
  return DownloadsController(ref);
});

class DownloadsController extends StateNotifier<Map<String, Transfer>> {
  DownloadsController(this.ref) : super({}) {
    unawaited(_restore());
  }
  final Ref ref;
  final _tokens = <String, CancelToken>{};
  final _done = <String, Completer<void>>{};
  Future<void> _restore() async {
    try {
      final library = await ref.read(deviceLibraryProvider.future);
      for (final row in await library.store.all('transfers')) {
        final track = Track.fromJson(row['track'] as Map<String, dynamic>);
        if (mounted && !state.containsKey(track.id)) {
          _set(Transfer(track, TransferStatus.paused));
        }
      }
    } catch (_) {/* Storage failures are displayed by the library screen. */}
  }

  void _set(Transfer transfer) {
    if (mounted) state = {...state, transfer.track.id: transfer};
  }

  Future<void> download(
      Track track, String url, Map<String, String>? headers) async {
    if (!supportsDeviceFiles ||
        isPersonalTrack(track.id) ||
        _tokens.containsKey(track.id)) {
      return;
    }
    final token = CancelToken();
    _tokens[track.id] = token;
    final done = Completer<void>();
    _done[track.id] = done;
    try {
      final library = await ref.read(deviceLibraryProvider.future);
      final existing = await library.file(track.id);
      if (existing != null && await deviceFileExists(existing.path)) {
        await library.store.remove('transfers', track.id);
        _set(Transfer(track, TransferStatus.completed,
            received: existing.bytes, total: existing.bytes));
        return;
      }
      if (token.isCancelled || !mounted) return;
      _set(Transfer(track, TransferStatus.running));
      await library.store.put('transfers', track.id,
          {'track': track.toJson(), 'status': 'interrupted'});
      final file = await downloadAudio(track, library.store.scope, url, headers,
          (received, total) {
        if (!token.isCancelled) {
          _set(Transfer(track, TransferStatus.running,
              received: received, total: total));
        }
      }, token);
      await library.saveFile(file);
      await library.store.remove('transfers', track.id);
      _set(Transfer(track, TransferStatus.completed,
          received: file.bytes, total: file.bytes));
      ref.invalidate(deviceTracksProvider);
      ref.read(libraryRevisionProvider.notifier).state++;
    } catch (error) {
      if (!token.isCancelled) {
        _set(Transfer(track, TransferStatus.failed,
            error: 'Téléchargement interrompu. Réessaie.'));
      }
    } finally {
      _tokens.remove(track.id);
      _done.remove(track.id);
      done.complete();
    }
  }

  Future<void> pause(String id) async {
    final transfer = state[id];
    _tokens[id]?.cancel('pause');
    if (transfer != null) _set(Transfer(transfer.track, TransferStatus.paused));
    await _done[id]?.future;
  }

  Future<void> cancel(String id) async {
    await pause(id);
    final library = await ref.read(deviceLibraryProvider.future);
    await library.store.remove('transfers', id);
    final transfer = state[id];
    if (transfer != null) {
      _set(Transfer(transfer.track, TransferStatus.cancelled));
    }
  }

  @override
  void dispose() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    super.dispose();
  }
}
