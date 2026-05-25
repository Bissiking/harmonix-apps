import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';

part 'tracks_provider.g.dart';

@riverpod
Future<List<Track>> tracks(TracksRef ref) =>
    ref.watch(catalogRepositoryProvider).getTracks();

@riverpod
Future<Track> trackDetail(TrackDetailRef ref, String trackId) =>
    ref.watch(catalogRepositoryProvider).getTrack(trackId);
