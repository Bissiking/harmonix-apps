import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/playlist.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/domain/library_sort.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/shared/widgets/music_collection.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/library/providers/favorites_provider.dart';
import 'package:harmonix_apps/features/library/providers/playlists_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/layout/content_constraints.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/features/library/presentation/device_library_screen.dart';
import 'package:harmonix_apps/features/library/presentation/library_groups.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider).valueOrNull ?? [];
    final recent = sortTracks(tracks, LibrarySort.recent,
        ref.watch(trackAddedDatesProvider).valueOrNull ?? {});
    return DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
              bottom: false,
              child: CollectionWidth(
                child: NestedScrollView(
                  headerSliverBuilder: (context, scrolled) => [
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                MediaQuery.sizeOf(context).width < 600
                                    ? 20
                                    : 32,
                                28,
                                24,
                                24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bibliothèque',
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
                                  Text(
                                      tracks.isEmpty
                                          ? 'Ta musique, à portée de main.'
                                          : '${tracks.length} titres. Tes albums, favoris et playlists.',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                  const SizedBox(height: 20),
                                  Wrap(spacing: 12, runSpacing: 8, children: [
                                    FilledButton.icon(
                                        onPressed: recent.isEmpty
                                            ? null
                                            : () => runFlowAction(
                                                context,
                                                () => ref
                                                    .read(
                                                        playerProvider.notifier)
                                                    .playFromQueue(recent, 0)),
                                        icon: const Icon(
                                            Icons.play_arrow_rounded),
                                        label: const Text('Tout écouter')),
                                    OutlinedButton.icon(
                                        onPressed: () => context.go('/search'),
                                        icon: const Icon(Icons.search_rounded),
                                        label: const Text('Rechercher')),
                                  ]),
                                ]))),
                    SliverPersistentHeader(
                        pinned: true,
                        delegate: _LibraryTabs(
                            Theme.of(context).scaffoldBackgroundColor)),
                  ],
                  body: const TabBarView(children: [
                    DeviceLibraryScreen(),
                    LibraryAlbumsTab(),
                    LibraryArtistsTab(),
                    _FavoritesTab(),
                    _PlaylistsTab(),
                    DevicePlaylistsTab(),
                  ]),
                ),
              )),
        ));
  }
}

class _LibraryTabs extends SliverPersistentHeaderDelegate {
  _LibraryTabs(this.background);
  final Color background;
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  bool shouldRebuild(covariant _LibraryTabs oldDelegate) =>
      background != oldDelegate.background;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(
          height: maxExtent,
          child: Material(
              color: background,
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Morceaux'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Artistes'),
                  Tab(text: 'Favoris'),
                  Tab(text: 'Playlists Sonora'),
                  Tab(text: 'Playlists mixtes')
                ],
              )));
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return AsyncValueWidget(
      value: favorites,
      onRetry: () => ref.invalidate(favoritesProvider),
      data: (tracks) => tracks.isEmpty
          ? const FlowEmptyState(
              icon: Icons.favorite_border,
              title: 'Aucun favori pour l\'instant',
              message:
                  'Touche le cœur d\'un titre pour le retrouver ici, même hors connexion.')
          : RefreshIndicator(
              onRefresh: () => ref.refresh(favoritesProvider.future),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: tracks.length,
                    itemBuilder: (_, i) => TrackListTile(
                      track: tracks[i],
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .playFromQueue(tracks, i),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    return AsyncValueWidget(
      value: playlists,
      onRetry: () => ref.invalidate(playlistsProvider),
      data: (items) => RefreshIndicator(
        onRefresh: () => ref.refresh(playlistsProvider.future),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: items.isEmpty
                ? FlowEmptyState(
                    icon: Icons.queue_music_outlined,
                    title: 'Aucune playlist',
                    message:
                        'Range tes titres Sonora dans une playlist : elle reste disponible hors connexion.',
                    action: FilledButton.tonalIcon(
                        onPressed: () => _createPlaylist(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une playlist')),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    itemCount: items.length + 1,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton.tonalIcon(
                            onPressed: () => _createPlaylist(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Créer une playlist'),
                          ),
                        );
                      }
                      return _PlaylistTile(playlist: items[index - 1]);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _CreatePlaylistDialog(),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    try {
      final playlist =
          await ref.read(playlistsActionsProvider.notifier).create(name.trim());
      if (context.mounted) {
        context.pushNamed(
          RouteNames.playlistDetail,
          pathParameters: {'id': playlist.id},
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de créer la playlist.')),
        );
      }
    }
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: TrackArtwork(
        coverFile: playlist.coverFile,
        size: 48,
        borderRadius: 8,
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.trackCount} piste${playlist.trackCount > 1 ? 's' : ''}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.pushNamed(
        RouteNames.playlistDetail,
        pathParameters: {'id': playlist.id},
      ),
    );
  }
}

class _CreatePlaylistDialog extends ConsumerStatefulWidget {
  const _CreatePlaylistDialog();

  @override
  ConsumerState<_CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<_CreatePlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nom de la playlist',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
