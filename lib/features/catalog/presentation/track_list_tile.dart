import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/shared/widgets/track_context_menu.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

class TrackListTile extends ConsumerWidget {
  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onRemove,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref
        .watch(deviceTracksProvider)
        .valueOrNull
        ?.where((f) => f.track.id == track.id)
        .firstOrNull;
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
        final localCenter = box?.localToGlobal(box.size.center(Offset.zero)) ??
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
        minTileHeight: 76,
        leading: TrackArtwork(
          trackId: track.id,
          coverFile: track.coverFile,
          coverUrl: track.coverUrl,
          size: 52,
          borderRadius: 10,
        ),
        title: Text(
          track.title.isNotEmpty ? track.title : track.id,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            track.artist.isNotEmpty ? track.artist : 'Artiste inconnu',
            if (device?.source.name == 'personal')
              'Cet appareil'
            else if (device != null)
              'Téléchargé'
            else if (track.album?.isNotEmpty == true)
              track.album!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
                container: true,
                child: FlowIconButton(
                    tooltip: 'Actions du titre',
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      final box = context.findRenderObject() as RenderBox;
                      showTrackContextMenu(context,
                          tapPosition:
                              box.localToGlobal(box.size.center(Offset.zero)),
                          track: track,
                          ref: ref,
                          onPlay: onTap);
                    })),
            if (onRemove != null)
              Semantics(
                  container: true,
                  child: FlowIconButton(
                    tooltip: 'Retirer de la playlist',
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: onRemove,
                  )),
            Text(
              track.durationMs > 0 ? formatMs(track.durationMs) : '--:--',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
