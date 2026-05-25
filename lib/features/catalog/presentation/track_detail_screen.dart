import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';

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
              if (t.album != null && t.album!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () async {
                    final albums = await ref.read(albumsProvider.future);
                    String? albumId;
                    for (final candidate in albums) {
                      if (candidate.title == t.album) {
                        albumId = candidate.id;
                        break;
                      }
                    }
                    if (albumId != null && context.mounted) {
                      context.pushNamed(
                        RouteNames.albumDetail,
                        pathParameters: {'id': albumId},
                      );
                    }
                  },
                  child: Text(
                    t.album!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
