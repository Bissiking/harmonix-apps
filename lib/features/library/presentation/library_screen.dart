import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/features/library/providers/favorites_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: AsyncValueWidget(
        value: favorites,
        data: (tracks) => tracks.isEmpty
            ? const Center(child: Text('Aucun favori pour l\'instant.'))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(favoritesProvider.future),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (_, i) => TrackListTile(
                        track: tracks[i],
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playFromQueue(tracks, i),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
