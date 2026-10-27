// mixed_playlist_sync.dart
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';

Map<String, dynamic> mixedPlaylistPayload(
    MixedPlaylist playlist, List<Track> tracks, int baseRevision,
    {bool deleted = false, String? operationId}) {
  final byId = {for (final track in tracks) track.id: track};
  return {
    'operationId': operationId ??
        '${playlist.id}:${playlist.revision}:${deleted ? "delete" : "save"}',
    'baseRevision': baseRevision,
    'name': playlist.name,
    'deleted': deleted,
    'entries': [
      for (final id in playlist.trackIds)
        {
          'trackId': id,
          'source': isPersonalTrack(id) ? 'local' : 'sonora',
          if (isPersonalTrack(id)) 'fingerprint': id.substring(6),
          'title': byId[id]?.title ?? '',
          'artist': byId[id]?.artist ?? '',
          'album': byId[id]?.album ?? '',
          'durationMs': byId[id]?.durationMs ?? 0,
        }
    ]
  };
}

class MixedPlaylistSync {
  MixedPlaylistSync(this.library, this.dio);
  final DeviceLibrary library;
  final Dio dio;
  static const path = '/api/harmonix/apps/v2/mixed-playlists';
  Future<int> synchronize() async {
    final tracks = await library.allTracks();
    final tombstones = (await library.store.all('playlist_tombstones'))
        .map(MixedPlaylist.fromJson)
        .toList();
    for (final playlist in [...await library.playlists(), ...tombstones]) {
      final status = await library.store.get('playlist_sync', playlist.id);
      if (status?['localRevision'] == playlist.revision) continue;
      final deleted = tombstones.any((p) => p.id == playlist.id);
      var operation =
          await library.store.get('playlist_operations', playlist.id);
      if (operation?['localRevision'] != playlist.revision ||
          operation?['deleted'] != deleted) {
        final random = Random.secure();
        operation = {
          'operationId': List.generate(16,
                  (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
              .join(),
          'localRevision': playlist.revision,
          'deleted': deleted
        };
        await library.store.put('playlist_operations', playlist.id, operation);
      }
      try {
        final response = await dio.put<dynamic>('$path/${playlist.id}',
            data: mixedPlaylistPayload(
                playlist, tracks, status?['serverRevision'] as int? ?? 0,
                deleted: deleted,
                operationId: operation!['operationId'] as String));
        final data = response.data as Map<String, dynamic>;
        await library.store.put('playlist_sync', playlist.id, {
          'localRevision': playlist.revision,
          'serverRevision': data['revision']
        });
        if (deleted) {
          await library.store.remove('playlist_tombstones', playlist.id);
        }
      } on DioException catch (error) {
        if (error.response?.statusCode != 409) rethrow;
        // Keep the local edit intact. Fetch the remote version below for explicit resolution.
        await library.store
            .put('playlist_conflicts', playlist.id, {'id': playlist.id});
      }
    }
    final response = await dio.get<dynamic>(path);
    final rows = (response.data as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      final id = row['id'] as String;
      if (await library.store.get('playlist_conflicts', id) != null) {
        await library.store.put('playlist_conflicts', id, row);
        continue;
      }
      final existing = await library.store.get('mixed_playlists', id);
      final status = await library.store.get('playlist_sync', id);
      // Never overwrite an edit made while a request was in flight.
      if (existing != null &&
          status?['localRevision'] != existing['revision']) {
        continue;
      }
      if (row['deleted'] == true) {
        await library.store.remove('mixed_playlists', id);
        continue;
      }
      final playlist = MixedPlaylist(
          id: id,
          name: row['name'] as String,
          keepOffline: existing?['keepOffline'] == true,
          revision: existing?['revision'] as int? ?? 0,
          trackIds: (row['entries'] as List)
              .map((entry) => entry['trackId'] as String)
              .toList());
      await library.savePlaylist(playlist);
      await library.store.put('playlist_sync', id, {
        'localRevision': playlist.revision,
        'serverRevision': row['revision']
      });
      for (final entry
          in (row['entries'] as List).cast<Map<String, dynamic>>()) {
        final track = Track(
            id: entry['trackId'] as String,
            title: entry['title'] as String? ?? '',
            artist: entry['artist'] as String? ?? '',
            album: entry['album'] as String?,
            durationMs: (entry['durationMs'] as num?)?.toInt() ?? 0);
        await library.store.put('playlist_snapshots', track.id, track.toJson());
      }
    }
    return (await library.store.all('playlist_conflicts')).length;
  }

  Future<void> preserveLocalAndAcceptRemote(String id) async {
    final local = await library.store.get('mixed_playlists', id);
    final remote = await library.store.get('playlist_conflicts', id);
    if (remote == null || remote['entries'] == null) return;
    final tombstone = await library.store.get('playlist_tombstones', id);
    final original = local != null
        ? MixedPlaylist.fromJson(local)
        : tombstone != null
            ? MixedPlaylist.fromJson(tombstone)
            : null;
    if (original != null && local != null) {
      final copy =
          await library.createPlaylist('${original.name} (copie locale)');
      await library.savePlaylist(copy.edit(trackIds: original.trackIds),
          baseRevision: copy.revision);
    }
    final revision = (original?.revision ?? 0) + 1;
    if (remote['deleted'] == true) {
      await library.store.remove('mixed_playlists', id);
    } else {
      await library.savePlaylist(MixedPlaylist(
          id: id,
          name: remote['name'] as String,
          keepOffline: original?.keepOffline ?? false,
          revision: revision,
          trackIds: (remote['entries'] as List)
              .map((entry) => entry['trackId'] as String)
              .toList()));
    }
    await library.store.put('playlist_sync', id,
        {'localRevision': revision, 'serverRevision': remote['revision']});
    await library.store.remove('playlist_tombstones', id);
    await library.store.remove('playlist_conflicts', id);
  }
}

final playlistConflictsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) async => (await ref.watch(deviceLibraryProvider.future))
        .store
        .all('playlist_conflicts'));
final mixedSyncStatusProvider = StateProvider<String?>((ref) {
  ref.watch(libraryScopeProvider);
  return null;
});
final mixedSyncBusyProvider = StateProvider<bool>((ref) {
  ref.watch(libraryScopeProvider);
  return false;
});
Future<void> synchronizeMixedPlaylists(
    Ref ref, bool Function() isActive) async {
  if (ref.read(offlineModeProvider) || ref.read(mixedSyncBusyProvider)) return;
  ref.read(mixedSyncBusyProvider.notifier).state = true;
  try {
    final bootstrap = await ref.read(bootstrapProvider.future);
    if (!isActive()) return;
    if (bootstrap.capabilities['mixed_playlists'] != true) {
      ref.read(mixedSyncStatusProvider.notifier).state =
          'Ce serveur ne prend pas encore en charge les playlists mixtes.';
      return;
    }
    final library = await ref.read(deviceLibraryProvider.future);
    if (!isActive()) return;
    final sync = MixedPlaylistSync(library, ref.read(dioProvider));
    final conflicts = await sync.synchronize();
    if (!isActive()) return;
    ref.read(mixedSyncStatusProvider.notifier).state = conflicts > 0
        ? '$conflicts conflits à résoudre. Tes versions locales sont conservées.'
        : 'Composition synchronisée. Les fichiers personnels restent sur cet appareil.';
    ref.invalidate(mixedPlaylistsProvider);
    ref.invalidate(playlistConflictsProvider);
  } catch (_) {
    if (isActive()) {
      ref.read(mixedSyncStatusProvider.notifier).state =
          'Synchronisation interrompue. Les modifications locales sont conservées.';
    }
  } finally {
    if (isActive()) ref.read(mixedSyncBusyProvider.notifier).state = false;
  }
}

final mixedSyncActionProvider = Provider<Future<void> Function()>((ref) {
  ref.watch(libraryScopeProvider);
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return () => synchronizeMixedPlaylists(ref, () => !disposed);
});

/// Startup, reconnect and periodic retry keep offline edits durable and eventual.
final mixedSyncLifecycleProvider = Provider<void>((ref) {
  ref.watch(deviceLibraryProvider);
  void retry() {
    if (!ref.read(offlineModeProvider)) {
      unawaited(ref.read(mixedSyncActionProvider)());
    }
  }

  final timer = Timer.periodic(const Duration(minutes: 1), (_) => retry());
  final initial = Timer(const Duration(seconds: 2), retry);
  ref.listen<bool>(offlineModeProvider, (previous, next) {
    if (previous == true && !next) retry();
  });
  ref.onDispose(() {
    timer.cancel();
    initial.cancel();
  });
});

final keptPlaylistDownloadsProvider = Provider<void>((ref) {
  ref.watch(deviceLibraryProvider);
  var running = false;
  var disposed = false;
  Future<void> maintain() async {
    if (running ||
        disposed ||
        !supportsDeviceFiles ||
        ref.read(offlineModeProvider)) {
      return;
    }
    running = true;
    try {
      final library = await ref.read(deviceLibraryProvider.future);
      final tracks = {for (final t in await library.allTracks()) t.id: t};
      final ids = {
        for (final p in await library.playlists())
          if (p.keepOffline) ...p.trackIds
      };
      for (final id in ids) {
        if (disposed || ref.read(offlineModeProvider)) break;
        final track = tracks[id];
        final transfer = ref.read(transfersProvider)[id];
        if (track == null ||
            isPersonalTrack(id) ||
            transfer?.status == TransferStatus.paused ||
            transfer?.status == TransferStatus.cancelled) {
          continue;
        }
        await ref.read(playerProvider.notifier).downloadTrack(track);
      }
    } catch (_) {
      /* A failed transfer remains visible and retriable. */
    } finally {
      running = false;
    }
  }

  final initial = Timer(const Duration(seconds: 3), maintain);
  final timer = Timer.periodic(const Duration(minutes: 1), (_) => maintain());
  ref.listen<bool>(offlineModeProvider, (before, after) {
    if (before == true && !after) unawaited(maintain());
  });
  ref.onDispose(() {
    disposed = true;
    initial.cancel();
    timer.cancel();
  });
});

final playlistTrackIndexProvider = FutureProvider<List<Track>>((ref) async {
  ref.watch(libraryRevisionProvider);
  ref.watch(mixedPlaylistsProvider);
  final library = await ref.watch(deviceLibraryProvider.future);
  final snapshots =
      (await library.store.all('playlist_snapshots')).map(Track.fromJson);
  return {
    for (final track in [...snapshots, ...await library.allTracks()])
      track.id: track
  }.values.toList();
});
