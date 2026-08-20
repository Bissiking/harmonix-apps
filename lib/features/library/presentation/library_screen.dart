import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/playlist.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/library/providers/favorites_provider.dart';
import 'package:harmonix_apps/features/library/providers/playlists_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/layout/content_constraints.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bibliothèque'),
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            tabs: [Tab(text: 'Favoris'), Tab(text: 'Playlists')],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoritesTab(),
            _PlaylistsTab(),
          ],
        ),
      ),
    );
  }
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
          ? const Center(child: Text('Aucun favori pour l\'instant.'))
          : RefreshIndicator(
              onRefresh: () => ref.refresh(favoritesProvider.future),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: ListView.builder(
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
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Aucune playlist pour l\'instant.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
      final playlist = await ref
          .read(playlistsActionsProvider.notifier)
          .create(name.trim());
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