import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';
import 'package:harmonix_apps/core/utils/trusted_origin.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';

/// Least recently used eviction, applied exclusively to temporary cache rows.
List<Map<String, dynamic>> cacheEvictions(
    List<Map<String, dynamic>> entries, int limit,
    {Set<String> protectedIds = const {}}) {
  final ordered = [...entries]..sort(
      (a, b) => (a['lastUsed'] as String).compareTo(b['lastUsed'] as String));
  var bytes =
      ordered.fold<int>(0, (sum, row) => sum + (row['file']['bytes'] as int));
  final evicted = <Map<String, dynamic>>[];
  for (final row in ordered) {
    if (bytes <= limit) break;
    if (protectedIds.contains(row['file']['track']['id'])) continue;
    evicted.add(row);
    bytes -= row['file']['bytes'] as int;
  }
  return evicted;
}

Future<DeviceTrack?> cachedAudio(DeviceLibrary library, String id) async {
  final row = await library.store.get('audio_cache', id);
  if (row == null) return null;
  final file = DeviceTrack.fromJson(row['file'] as Map<String, dynamic>);
  if (!await deviceFileExists(file.path)) {
    await library.store.remove('audio_cache', id);
    return null;
  }
  await library.store.put('audio_cache', id,
      {...row, 'lastUsed': DateTime.now().toIso8601String()});
  return file;
}

class AudioCacheController {
  AudioCacheController(this.ref);
  final Ref ref;
  bool disposed = false;
  bool _busy = false;
  int _generation = 0;
  CancelToken? _token;
  Future<void> trim(int limit, {bool protectQueue = false}) async {
    final library = await ref.read(deviceLibraryProvider.future);
    final protectedIds = protectQueue
        ? ref
            .read(audioHandlerProvider)
            .queue
            .value
            .map((item) => item.id)
            .toSet()
        : <String>{};
    for (final row in cacheEvictions(
        await library.store.all('audio_cache'), limit,
        protectedIds: protectedIds)) {
      final file = DeviceTrack.fromJson(row['file'] as Map<String, dynamic>);
      await removeDeviceFile(file.path, library.store.scope);
      await library.store.remove('audio_cache', file.track.id);
    }
    if (!disposed) ref.invalidate(audioCacheEntriesProvider);
  }

  Future<void> clear() async {
    _generation++;
    _token?.cancel();
    await trim(0);
  }

  Future<void> remember(Track track) async {
    if (disposed ||
        _busy ||
        !supportsDeviceFiles ||
        isPersonalTrack(track.id)) {
      return;
    }
    final settings = ref.read(settingsRepositoryProvider);
    if (!settings.audioCacheEnabled || ref.read(offlineModeProvider)) return;
    _busy = true;
    final generation = _generation;
    try {
      final library = await ref.read(deviceLibraryProvider.future);
      if (await library.file(track.id) != null ||
          await cachedAudio(library, track.id) != null) {
        return;
      }
      if (disposed || generation != _generation) return;
      // Reserve half the budget before transfer. Large individual tracks are
      // skipped rather than growing the cache beyond its configured limit.
      final limit = settings.audioCacheLimitMb * 1024 * 1024;
      await trim(limit ~/ 2, protectQueue: true);
      if (disposed || generation != _generation) return;
      final used = (await library.store.all('audio_cache'))
          .fold<int>(0, (sum, row) => sum + (row['file']['bytes'] as int));
      final reserve = limit - used;
      if (reserve <= 0) return;
      final token = CancelToken();
      _token = token;
      final url = streamUrl(settings.serverUrl, track.id);
      final file = await downloadAudio(track, library.store.scope, url,
          serverHeaders(settings.serverUrl, url, settings.authToken),
          (received, total) {
        if (received > reserve || total > reserve) token.cancel('cache_budget');
      }, token, temporary: true);
      if (disposed || token.isCancelled || generation != _generation) {
        await removeDeviceFile(file.path, library.store.scope);
        return;
      }
      await library.store.put('audio_cache', track.id, {
        'file': file.toJson(),
        'lastUsed': DateTime.now().toIso8601String()
      });
      ref.invalidate(audioCacheEntriesProvider);
    } catch (_) {
      /* Best-effort cache never interrupts the active player. */
    } finally {
      _busy = false;
      _token = null;
    }
  }

  void dispose() {
    disposed = true;
    _token?.cancel();
  }
}

final audioCacheEntriesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) async => (await ref.watch(deviceLibraryProvider.future))
        .store
        .all('audio_cache'));
final audioCacheControllerProvider = Provider<AudioCacheController>((ref) {
  ref.watch(libraryScopeProvider);
  final controller = AudioCacheController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
final audioCacheLifecycleProvider = Provider<void>((ref) {
  final controller = ref.watch(audioCacheControllerProvider);
  ref.listen(nowPlayingProvider, (_, next) {
    final item = next.valueOrNull;
    if (item == null || item.extras?['source'] != 'sonora') return;
    unawaited(controller.remember(Track(
        id: item.id,
        title: item.title,
        artist: item.artist ?? '',
        album: item.album,
        durationMs: item.duration?.inMilliseconds ?? 0,
        coverFile: item.extras?['coverFile'] as String?,
        coverUrl: item.extras?['coverUrl'] as String?)));
  });
});
