import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/providers/catalog_client_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';

part 'search_repository.g.dart';

@riverpod
Future<List<Track>> searchTracks(SearchTracksRef ref, String query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(catalogClientProvider).search(query);
}
