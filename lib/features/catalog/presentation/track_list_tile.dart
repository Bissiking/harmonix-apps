import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/track.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../features/player/providers/player_provider.dart';
import '../../../shared/widgets/track_artwork.dart';

class TrackListTile extends ConsumerWidget {
  const TrackListTile({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: TrackArtwork(coverFile: track.coverFile),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatMs(track.durationMs),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => ref.read(playerProvider.notifier).playTrack(track),
      onLongPress: () => context.pushNamed('track-detail', pathParameters: {'id': track.id}),
    );
  }
}
