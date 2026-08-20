import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final albums = ref.watch(albumsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ExplorerHeader(onSearch: () => context.go('/search')),
              Expanded(
                child: TabBarView(
                  children: [
                    AsyncValueWidget(
                      value: tracks,
                      onRetry: () => ref.invalidate(tracksProvider),
                      data: (items) => items.isEmpty
                          ? _EmptyCatalog(
                              icon: Icons.music_off_outlined,
                              message: 'Aucun titre public pour le moment.',
                              onRefresh: () => ref.invalidate(tracksProvider),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  ref.refresh(tracksProvider.future),
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 32),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) => Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 980),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: TrackListTile(
                                        track: items[index],
                                        onTap: () => ref
                                            .read(playerProvider.notifier)
                                            .playFromQueue(items, index),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    AsyncValueWidget(
                      value: albums,
                      onRetry: () => ref.invalidate(albumsProvider),
                      data: (items) => items.isEmpty
                          ? _EmptyCatalog(
                              icon: Icons.album_outlined,
                              message: 'Aucun album disponible pour le moment.',
                              onRefresh: () => ref.invalidate(albumsProvider),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  ref.refresh(albumsProvider.future),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final columns = width >= 1400
                                      ? 6
                                      : width >= 1080
                                          ? 5
                                          : width >= 760
                                              ? 4
                                              : width >= 520
                                                  ? 3
                                                  : 2;
                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 10, 20, 32),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.78,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (_, index) =>
                                        _AlbumTile(album: items[index]),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({
    required this.icon,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }
}

class _ExplorerHeader extends StatelessWidget {
  const _ExplorerHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1020),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explorer',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'Rechercher dans le catalogue',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onSearch,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded),
                        const SizedBox(width: 12),
                        Text(
                          'Artiste, titre ou album',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                tabs: [Tab(text: 'Titres'), Tab(text: 'Albums')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.pushNamed(
        RouteNames.albumDetail,
        pathParameters: {'id': album.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => TrackArtwork(
                coverFile: album.coverFile,
                coverUrl: album.coverUrl,
                size: constraints.maxWidth,
                borderRadius: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
