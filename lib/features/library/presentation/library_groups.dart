import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/core/utils/duration_formatter.dart';

class LibraryAlbumsTab extends ConsumerWidget {
  const LibraryAlbumsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueWidget(
      value: ref.watch(albumsProvider),
      data: (albums) => albums.isEmpty
          ? const FlowEmptyState(
              icon: Icons.album_outlined,
              title: 'Aucun album',
              message:
                  'Les albums Sonora apparaîtront ici après leur premier chargement.')
          : LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          (constraints.maxWidth / 210).floor().clamp(1, 6),
                      mainAxisExtent:
                          160 + 80 * MediaQuery.textScalerOf(context).scale(1),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16),
                  itemCount: albums.length,
                  itemBuilder: (context, i) => FlowFocusTile(
                      onPressed: () =>
                          context.push('/catalog/album/${albums[i].id}'),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TrackArtwork(
                                coverFile: albums[i].coverFile,
                                coverUrl: albums[i].coverUrl,
                                size: 138),
                            const SizedBox(height: 12),
                            Text(albums[i].title,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(albums[i].artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])))));
}

class LibraryArtistsTab extends ConsumerWidget {
  const LibraryArtistsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueWidget(
      value: ref.watch(tracksProvider),
      data: (tracks) {
        final artists = tracks
            .map((t) => t.artist)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        if (artists.isEmpty) {
          return const FlowEmptyState(
              icon: Icons.person_outline,
              title: 'Aucun artiste',
              message:
                  'Les artistes sont regroupés depuis les métadonnées de ta musique.');
        }
        final counts = <String, int>{};
        for (final track in tracks) {
          counts.update(track.artist, (value) => value + 1, ifAbsent: () => 1);
        }
        return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(artists[i]),
                subtitle: Text('${counts[artists[i]]} titres'),
                onTap: () => context
                    .push('/artists/${Uri.encodeComponent(artists[i])}')));
      });
}

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.artist});
  final String artist;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: Text(artist)),
      body: AsyncValueWidget(
          value: ref.watch(tracksProvider),
          data: (all) {
            final tracks = all.where((t) => t.artist == artist).toList();
            final duration =
                tracks.fold<int>(0, (sum, track) => sum + track.durationMs);
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(artist,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('${tracks.length} titres · ${formatMs(duration)}'),
                        const SizedBox(height: 16),
                        Wrap(spacing: 12, runSpacing: 8, children: [
                          FilledButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Lire'),
                              onPressed: tracks.isEmpty
                                  ? null
                                  : () => runFlowAction(
                                      context,
                                      () => ref
                                          .read(playerProvider.notifier)
                                          .playFromQueue(tracks, 0))),
                          OutlinedButton.icon(
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Aléatoire'),
                              onPressed: tracks.isEmpty
                                  ? null
                                  : () => runFlowAction(
                                      context,
                                      () => ref
                                          .read(playerProvider.notifier)
                                          .playFromQueue(
                                              [...tracks]..shuffle(Random()),
                                              0))),
                          if (supportsDeviceFiles)
                            OutlinedButton.icon(
                                icon: const Icon(Icons.download),
                                label: const Text('Télécharger'),
                                onPressed: tracks.isEmpty
                                    ? null
                                    : () => runFlowAction(context, () async {
                                          for (final track in tracks.where(
                                              (t) => !isPersonalTrack(t.id))) {
                                            await ref
                                                .read(playerProvider.notifier)
                                                .downloadTrack(track);
                                          }
                                        })),
                        ]),
                      ]))),
              SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, i) => TrackListTile(
                      track: tracks[i],
                      onTap: () => runFlowAction(
                          context,
                          () => ref
                              .read(playerProvider.notifier)
                              .playFromQueue(tracks, i)))),
            ]);
          }));
}
