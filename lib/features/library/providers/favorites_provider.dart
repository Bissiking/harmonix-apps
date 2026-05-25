import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/data/library_repository.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  @override
  Future<List<Track>> build() =>
      ref.watch(libraryRepositoryProvider).getFavorites();

  /// Optimistic toggle: flips immediately, reverts on error.
  Future<void> toggle(Track track) async {
    final previous = state;
    final currentList = state.valueOrNull ?? [];

    final isFav = currentList.any((t) => t.id == track.id);
    final optimistic = isFav
        ? currentList.where((t) => t.id != track.id).toList()
        : [...currentList, track.copyWith(isFavorite: true)];

    state = AsyncData(optimistic);

    try {
      await ref.read(libraryRepositoryProvider).toggleFavorite(track.id);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}
