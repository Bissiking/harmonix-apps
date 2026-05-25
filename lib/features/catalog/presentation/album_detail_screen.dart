import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = ref.watch(albumDetailProvider(albumId));

    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: AsyncValueWidget(
        value: album,
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: TrackArtwork(
                coverFile: a.coverFile,
                coverUrl: a.coverUrl,
                size: 200,
                borderRadius: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              a.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              a.artist,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${a.tracks.length} pistes • ${formatMs(a.totalDurationMs)}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(playerProvider.notifier).playFromQueue(a.tracks, 0),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Lire'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shuffled = [...a.tracks]..shuffle(Random());
                      await ref.read(playerProvider.notifier).playFromQueue(shuffled, 0);
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < a.tracks.length; i++)
              TrackListTile(
                track: a.tracks[i],
                onTap: () => ref.read(playerProvider.notifier).playFromQueue(a.tracks, i),
              ),
          ],
        ),
      ),
    );
  }
}
