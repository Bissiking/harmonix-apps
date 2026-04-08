import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../features/player/providers/player_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/track_artwork.dart';
import '../providers/tracks_provider.dart';

class TrackDetailScreen extends ConsumerWidget {
  const TrackDetailScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackDetailProvider(trackId));

    return Scaffold(
      appBar: AppBar(title: const Text('Piste')),
      body: AsyncValueWidget(
        value: track,
        data: (t) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TrackArtwork(
                coverFile: t.coverFile,
                coverUrl: t.coverUrl,
                size: 220,
                borderRadius: 16,
              ),
              const SizedBox(height: 24),
              Text(
                t.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                t.artist,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (t.album != null) ...[
                const SizedBox(height: 2),
                Text(
                  t.album!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                formatMs(t.durationMs),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(playerProvider.notifier).playTrack(t),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Lire'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
