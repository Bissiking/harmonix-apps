import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';

/// Connects the single audio_service MediaSession to the Android Auto catalog.
class AutoBridge {
  AutoBridge._();

  static void register(WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);

    handler.configureAndroidAuto(
      loadCatalog: () async {
        final tracks = await ref.read(catalogRepositoryProvider).getTracks();
        return _toMediaItems(ref, tracks);
      },
      search: (query) async {
        final tracks = await ref.read(catalogRepositoryProvider).search(query);
        return _toMediaItems(ref, tracks);
      },
      playFromMediaId: (mediaId) async {
        final repository = ref.read(catalogRepositoryProvider);
        try {
          final tracks = await repository.getTracks();
          final index = tracks.indexWhere((track) => track.id == mediaId);
          if (index >= 0) {
            await ref
                .read(playerProvider.notifier)
                .playFromQueue(tracks, index);
            return;
          }
        } catch (_) {
          // The direct track endpoint below can still work if the catalog fails.
        }

        final track = await repository.getTrack(mediaId);
        await ref.read(playerProvider.notifier).playTrack(track);
      },
    );
  }

  static List<MediaItem> _toMediaItems(WidgetRef ref, List<Track> tracks) {
    final baseUrl = ref.read(settingsRepositoryProvider).serverUrl;
    return tracks.map((track) => _toMediaItem(baseUrl, track)).toList();
  }

  static MediaItem _toMediaItem(String baseUrl, Track track) {
    final cover = track.coverFile ?? track.coverUrl;
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: Duration(milliseconds: track.durationMs),
      artUri: cover == null || cover.isEmpty
          ? null
          : Uri.tryParse(coverUrl(baseUrl, cover)),
      playable: true,
      extras: {
        if (track.coverFile != null) 'coverFile': track.coverFile!,
        if (track.coverUrl != null) 'coverUrl': track.coverUrl!,
      },
    );
  }
}
