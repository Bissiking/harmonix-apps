import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';

part 'search_repository.g.dart';

@riverpod
Future<List<Track>> searchTracks(SearchTracksRef ref, String query) async {
  if (query.trim().isEmpty) return Future.value([]);
  final metadata = await ref.watch(nightMetadataProvider.future);
  return (await ref.watch(catalogRepositoryProvider).search(query))
      .where((t) => metadata[t.id]?.nightOnly != true)
      .toList();
}
