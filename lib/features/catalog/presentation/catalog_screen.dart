import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/shared/layout/content_constraints.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final albums = ref.watch(albumsProvider);
    final isWide = ResponsiveBreakpoints.isTablet(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Pistes'),
                Tab(text: 'Albums'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AsyncValueWidget(
                    value: tracks,
                    data: (list) => RefreshIndicator(
                      onRefresh: () => ref.refresh(tracksProvider.future),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
	constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: list.length,
                            itemBuilder: (_, i) => TrackListTile(
                              track: list[i],
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playFromQueue(list, i),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AsyncValueWidget(
                    value: albums,
                    data: (list) => RefreshIndicator(
                      onRefresh: () => ref.refresh(albumsProvider.future),
                      child: isWide
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final album = list[i];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => context.pushNamed(
                                    RouteNames.albumDetail,
                                    pathParameters: {'id': album.id},
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: TrackArtwork(
                                            coverFile: album.coverFile,
                                            coverUrl: album.coverUrl,
                                            size: 140,
                                            borderRadius: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          album.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          album.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final album = list[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: TrackArtwork(
                                    coverFile: album.coverFile,
                                    coverUrl: album.coverUrl,
                                  ),
                                  title: Text(album.title),
                                  subtitle: Text(
                                      '${album.artist} • ${album.tracks.length} pistes'),
                                  onTap: () => context.pushNamed(
                                    RouteNames.albumDetail,
                                    pathParameters: {'id': album.id},
                                  ),
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
    );
  }
}
