// tv_surfaces.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';

class TvCatalogSurface extends ConsumerWidget {
  const TvCatalogSurface({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final albums = ref.watch(albumsProvider).valueOrNull ?? [];
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('À écouter'), actions: [
          FlowIconButton(
              tooltip: 'Rechercher',
              icon: const Icon(Icons.search),
              onPressed: () => context.go('/search'))
        ]),
        body: tracks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => FlowEmptyState(
                icon: Icons.cloud_off,
                title: 'Catalogue indisponible',
                message: 'Retrouve tes téléchargements dans la bibliothèque.',
                action: FilledButton(
                    onPressed: () => ref.invalidate(tracksProvider),
                    child: const Text('Réessayer'))),
            data: (items) => ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    children: [
                      Text('Ta musique sur grand écran',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      SizedBox(
                          height: 310,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) => SizedBox(
                                  width: 220,
                                  child: FlowFocusTile(
                                      autofocus: i == 0,
                                      onPressed: () =>
                                          runFlowAction(context, () async {
                                            await ref
                                                .read(playerProvider.notifier)
                                                .playFromQueue(items, i);
                                            if (context.mounted) {
                                              context.go('/player');
                                            }
                                          }),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TrackArtwork(
                                                coverFile: items[i].coverFile,
                                                coverUrl: items[i].coverUrl,
                                                size: 196,
                                                trackId: items[i].id),
                                            const SizedBox(height: 12),
                                            Text(items[i].title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge),
                                            Text(items[i].artist,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ]))))),
                      const SizedBox(height: 24),
                      Text('Albums',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      SizedBox(
                          height: 280,
                          child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: albums.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) => SizedBox(
                                  width: 220,
                                  child: FlowFocusTile(
                                      onPressed: () => context.push(
                                          '/catalog/album/${albums[i].id}'),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TrackArtwork(
                                                coverFile: albums[i].coverFile,
                                                coverUrl: albums[i].coverUrl,
                                                size: 196),
                                            const SizedBox(height: 12),
                                            Text(albums[i].title,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ]))))),
                    ])));
  }
}

class TvPlayerSurface extends ConsumerWidget {
  const TvPlayerSurface({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(nowPlayingProvider).valueOrNull;
    final state = ref.watch(playbackStateStreamProvider).valueOrNull;
    final queue = ref.watch(playbackQueueProvider).valueOrNull ?? [];
    final position =
        ref.watch(playbackPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(playbackDurationProvider).valueOrNull ??
        item?.duration ??
        Duration.zero;
    final player = ref.read(playerProvider.notifier);
    if (item == null) {
      return const FlowEmptyState(
          icon: Icons.headphones,
          title: 'Prêt pour ton écoute',
          message: 'Choisis un titre dans le catalogue.');
    }
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('En écoute')),
        body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Wrap(
                        spacing: 48,
                        runSpacing: 24,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TrackArtwork(
                              coverFile: item.extras?['coverFile'] as String?,
                              coverUrl: item.extras?['coverUrl'] as String?,
                              trackId: item.id,
                              size: (constraints.maxHeight * .65)
                                  .clamp(180, 360)),
                          SizedBox(
                              width:
                                  (constraints.maxWidth - 440).clamp(300, 640),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    const SizedBox(height: 12),
                                    Text(item.artist ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 12),
                                    Text(item.extras?['source'] == 'personal'
                                        ? 'Fichier personnel · cet appareil'
                                        : item.extras?['source'] == 'downloaded'
                                            ? 'Sonora · téléchargé'
                                            : 'Sonora · streaming'),
                                    const SizedBox(height: 24),
                                    Slider(
                                        value: position.inMilliseconds
                                            .clamp(0, duration.inMilliseconds)
                                            .toDouble(),
                                        max: duration.inMilliseconds > 0
                                            ? duration.inMilliseconds.toDouble()
                                            : 1,
                                        semanticFormatterCallback: (value) =>
                                            '${value ~/ 1000} secondes',
                                        onChanged: (v) => player.seek(
                                            Duration(milliseconds: v.toInt()))),
                                    Wrap(spacing: 16, children: [
                                      FlowIconButton(
                                          tooltip: 'Précédent',
                                          iconSize: 48,
                                          onPressed: player.skipToPrevious,
                                          icon:
                                              const Icon(Icons.skip_previous)),
                                      FilledButton(
                                          autofocus: true,
                                          onPressed: () {
                                            state?.playing == true
                                                ? player.pause()
                                                : player.play();
                                          },
                                          child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                  state?.playing == true
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  size: 48))),
                                      FlowIconButton(
                                          tooltip: 'Suivant',
                                          iconSize: 48,
                                          onPressed: player.skipToNext,
                                          icon: const Icon(Icons.skip_next)),
                                    ]),
                                    const SizedBox(height: 32),
                                    Text('À suivre',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    for (var i = 0; i < queue.length; i++)
                                      ListTile(
                                          title: Text(queue[i].title),
                                          selected: item.id == queue[i].id,
                                          onTap: () => ref
                                              .read(audioHandlerProvider)
                                              .skipToQueueItem(i)),
                                  ])),
                        ])))));
  }
}
