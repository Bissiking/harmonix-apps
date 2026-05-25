import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class TrackListTile extends StatelessWidget {
  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
  });

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: TrackArtwork(
        coverFile: track.coverFile,
        coverUrl: track.coverUrl,
      ),
      title: Text(
        track.title.isNotEmpty ? track.title : track.id,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist.isNotEmpty ? track.artist : 'Unknown artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        track.durationMs > 0 ? formatMs(track.durationMs) : '--:--',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
      onLongPress: () => context.pushNamed('track-detail', pathParameters: {'id': track.id}),
    );
  }
}
