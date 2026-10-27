import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

/// Shared reading width. The shell owns navigation; each collection owns its
/// scroll position and adapts to the space left by that navigation.
class CollectionWidth extends StatelessWidget {
  const CollectionWidth({super.key, required this.child, this.maxWidth = 1280});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: child));
}

class CollectionHeading extends StatelessWidget {
  const CollectionHeading(
      {super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ])),
        if (trailing != null) trailing!,
      ]));
}

class MusicCoverTile extends StatelessWidget {
  const MusicCoverTile(
      {super.key, required this.track, required this.onTap, this.size = 156});
  final Track track;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          TrackArtwork(
                              trackId: track.id,
                              coverFile: track.coverFile,
                              coverUrl: track.coverUrl,
                              size: size - 8,
                              borderRadius: 12),
                          Positioned(
                              right: 8,
                              bottom: 8,
                              child: ExcludeSemantics(
                                  child: Material(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: const CircleBorder(),
                                      child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(Icons.play_arrow_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              size: 22))))),
                        ]),
                        const SizedBox(height: 12),
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ])))));
}

class MusicCoverShelf extends StatelessWidget {
  const MusicCoverShelf(
      {super.key, required this.tracks, required this.onPlay, this.size = 156});
  final List<Track> tracks;
  final ValueChanged<int> onPlay;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: size + 16 + 50 * MediaQuery.textScalerOf(context).scale(1),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, index) => MusicCoverTile(
            track: tracks[index], size: size, onTap: () => onPlay(index)),
      ));
}

/// A finite skeleton keeps the layout readable without perpetual animation.
class CollectionLoading extends StatelessWidget {
  const CollectionLoading({super.key});
  @override
  Widget build(BuildContext context) => ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(20),
      itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            DecoratedBox(
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                child: const SizedBox.square(dimension: 52)),
            const SizedBox(width: 16),
            Expanded(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4)),
                    child: const SizedBox(height: 8))),
          ])));
}
