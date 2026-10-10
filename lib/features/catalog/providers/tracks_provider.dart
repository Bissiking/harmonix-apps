import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';

part 'tracks_provider.g.dart';

@riverpod
Future<List<Track>> tracks(TracksRef ref) async {
  ref.watch(libraryRevisionProvider);
  ref.watch(offlineModeProvider);
  final metadata = await ref.watch(nightMetadataProvider.future);
  return (await ref.watch(catalogRepositoryProvider).getTracks())
      .where((t) => metadata[t.id]?.nightOnly != true)
      .toList();
}

@riverpod
Future<Track> trackDetail(TrackDetailRef ref, String trackId) =>
    ref.watch(catalogRepositoryProvider).getTrack(trackId);
