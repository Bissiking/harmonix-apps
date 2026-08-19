import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/shared/widgets/track_context_menu.dart';

class TrackListTile extends ConsumerWidget {
  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
  });

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onSecondaryTapDown: (details) => showTrackContextMenu(
        context,
        tapPosition: details.globalPosition,
        track: track,
        ref: ref,
        onPlay: onTap,
      ),
      onLongPress: () {
        final box = context.findRenderObject() as RenderBox?;
        final localCenter =
            box?.localToGlobal(box.size.center(Offset.zero)) ??
                const Offset(200, 0);
        showTrackContextMenu(
          context,
          tapPosition: localCenter,
          track: track,
          ref: ref,
          onPlay: onTap,
        );
      },
      child: ListTile(
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
      ),
    );
  }
}