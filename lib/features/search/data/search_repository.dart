import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/catalog_client_provider.dart';
import '../../../core/models/track.dart';

part 'search_repository.g.dart';

@riverpod
Future<List<Track>> searchTracks(SearchTracksRef ref, String query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(catalogClientProvider).search(query);
}
