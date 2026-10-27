import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/night/domain/night_visibility.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';

part 'tracks_provider.g.dart';

@riverpod
Future<List<Track>> tracks(TracksRef ref) async {
  ref.watch(libraryRevisionProvider);
  ref.watch(offlineModeProvider);
  final metadata = await ref.watch(nightMetadataProvider.future);
  final tracks = await ref.watch(catalogRepositoryProvider).getTracks();
  // cacheCatalog stamps new titles during the fetch. Reload dates afterwards
  // so a concurrent first read cannot keep an empty or outdated sort order.
  ref.invalidate(trackAddedDatesProvider);
  ref.invalidate(deviceTracksProvider);
  return visibleInLibrary(tracks, metadata);
}

@riverpod
Future<Track> trackDetail(TrackDetailRef ref, String trackId) =>
    ref.watch(catalogRepositoryProvider).getTrack(trackId);
