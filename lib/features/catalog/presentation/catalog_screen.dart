import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/domain/library_sort.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/music_collection.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String section = 'Découvrir';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tracksProvider);
    final tracks = sortTracks(state.valueOrNull ?? [], LibrarySort.recent,
        ref.watch(trackAddedDatesProvider).valueOrNull ?? {});
    final albumState = ref.watch(albumsProvider);
    final albums = albumState.valueOrNull ?? [];
    final scheme = Theme.of(context).colorScheme;
    void play(int index) => runFlowAction(context,
        () => ref.read(playerProvider.notifier).playFromQueue(tracks, index));
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            bottom: false,
            child: CollectionWidth(
              child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tracksProvider);
                    ref.invalidate(albumsProvider);
                    await ref.read(tracksProvider.future);
                  },
                  child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            sliver: SliverToBoxAdapter(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Explorer',
                                      style: (MediaQuery.textScalerOf(context)
                                                      .scale(1) >
                                                  1.5
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                              : Theme.of(context)
                                                  .textTheme
                                                  .headlineLarge)
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1)),
                                  const SizedBox(height: 8),
                                  Text('La prochaine musique qui restera.',
                                      style: TextStyle(
                                          color: scheme.onSurfaceVariant)),
                                  const SizedBox(height: 24),
                                  Material(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: () => context.go('/search'),
                                          child: Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Row(children: [
                                                const Icon(
                                                    Icons.search_rounded),
                                                const SizedBox(width: 12),
                                                const Expanded(
                                                    child: Text(
                                                        'Artiste, titre ou album')),
                                                Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color:
                                                        scheme.onSurfaceVariant)
                                              ])))),
                                  const SizedBox(height: 20),
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    for (final name in [
                                      'Découvrir',
                                      'Titres',
                                      'Albums'
                                    ])
                                      ChoiceChip(
                                          label: Text(name),
                                          selected: section == name,
                                          onSelected: (_) =>
                                              setState(() => section = name)),
                                  ]),
                                ]))),
                        if (state.isLoading ||
                            (section == 'Albums' && albumState.isLoading))
                          const SliverToBoxAdapter(
                              child: SizedBox(
                                  height: 240, child: CollectionLoading())),
                        if (state.hasError ||
                            (section == 'Albums' && albumState.hasError))
                          SliverToBoxAdapter(
                              child: FlowEmptyState(
                                  icon: Icons.cloud_off,
                                  title: 'Le catalogue est indisponible',
                                  message: 'Actualise pour retrouver Sonora.',
                                  action: FilledButton(
                                      onPressed: () {
                                        ref.invalidate(tracksProvider);
                                        ref.invalidate(albumsProvider);
                                      },
                                      child: const Text('Réessayer')))),
                        if (section == 'Découvrir' && tracks.isNotEmpty)
                          SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                              sliver: SliverToBoxAdapter(
                                  child: _FeaturedRelease(
                                      track: tracks.first,
                                      onPlay: () => play(0)))),
                        if (section != 'Titres' && albums.isNotEmpty) ...[
                          SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              sliver: SliverToBoxAdapter(
                                  child: CollectionHeading(
                                      title: 'À travers les albums',
                                      subtitle:
                                          '${albums.length} albums à parcourir'))),
                          SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              sliver: SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                final columns =
                                    (constraints.crossAxisExtent / 200)
                                        .floor()
                                        .clamp(2, 6);
                                final extent = (constraints.crossAxisExtent -
                                        20 * (columns - 1)) /
                                    columns;
                                return SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            crossAxisSpacing: 20,
                                            mainAxisSpacing: 20,
                                            mainAxisExtent: extent +
                                                68 *
                                                    MediaQuery.textScalerOf(
                                                            context)
                                                        .scale(1)),
                                    itemCount: albums.length,
                                    itemBuilder: (context, index) {
                                      final album = albums[index];
                                      return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () => context.push(
                                                  '/catalog/album/${album.id}'),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TrackArtwork(
                                                        trackId: album.tracks
                                                            .firstOrNull?.id,
                                                        coverFile:
                                                            album.coverFile,
                                                        coverUrl:
                                                            album.coverUrl,
                                                        size: extent,
                                                        borderRadius: 12),
                                                    const SizedBox(height: 12),
                                                    Text(album.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                    const SizedBox(height: 4),
                                                    Text(album.artist,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color: scheme
                                                                .onSurfaceVariant)),
                                                  ])));
                                    });
                              })),
                        ],
                        if (section != 'Albums' && tracks.isNotEmpty) ...[
                          SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              sliver: SliverToBoxAdapter(
                                  child: CollectionHeading(
                                      title: 'À la suite',
                                      subtitle:
                                          '${tracks.length} titres du catalogue'))),
                          SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              sliver: SliverList.builder(
                                  itemCount: tracks.length,
                                  itemBuilder: (_, index) => TrackListTile(
                                      track: tracks[index],
                                      onTap: () => play(index)))),
                        ],
                        if (!state.isLoading &&
                            !state.hasError &&
                            (section == 'Albums'
                                ? albums.isEmpty &&
                                    !albumState.isLoading &&
                                    !albumState.hasError
                                : tracks.isEmpty))
                          const SliverToBoxAdapter(
                              child: FlowEmptyState(
                                  icon: Icons.library_music_outlined,
                                  title: 'La découverte commence ici',
                                  message:
                                      'Les titres et albums publics de Sonora apparaîtront ici.')),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ])),
            )));
  }
}

class _FeaturedRelease extends StatelessWidget {
  const _FeaturedRelease({required this.track, required this.onPlay});
  final Track track;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final scheme = Theme.of(context).colorScheme;
        final artwork = TrackArtwork(
            trackId: track.id,
            coverFile: track.coverFile,
            coverUrl: track.coverUrl,
            size: stacked
                ? constraints.maxWidth - 32
                : wide
                    ? 208
                    : 96,
            borderRadius: 12);
        final details =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(track.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: (wide
                      ? Theme.of(context).textTheme.headlineLarge
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(track.artist, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Écouter')),
        ]);
        return Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
                padding: EdgeInsets.all(wide ? 28 : 16),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            artwork,
                            const SizedBox(height: 20),
                            details
                          ])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                            artwork,
                            SizedBox(width: wide ? 32 : 16),
                            Expanded(child: details)
                          ])));
      });
}
