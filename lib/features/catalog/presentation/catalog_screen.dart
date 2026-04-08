import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/player/providers/player_provider.dart';
import '../providers/tracks_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import 'track_list_tile.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: AsyncValueWidget(
        value: tracks,
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(tracksProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: list.length,
            itemBuilder: (_, i) => TrackListTile(
              track: list[i],
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playFromQueue(list, i),
            ),
          ),
        ),
      ),
    );
  }
}
