import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/playlist.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/library/providers/favorites_provider.dart';
import 'package:harmonix_apps/features/library/providers/playlists_provider.dart';

/// Affiche le menu contextuel d'une piste (clic droit sur desktop,
/// pression longue sur tactile).
Future<void> showTrackContextMenu(
  BuildContext context, {
  required Offset tapPosition,
  required Track track,
  required WidgetRef ref,
  required VoidCallback onPlay,
}) async {
  final favorites = ref.read(favoritesProvider).valueOrNull ?? const <Track>[];
  final isFavorite = favorites.any((t) => t.id == track.id);
  final overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;
  final relative = RelativeRect.fromRect(
    tapPosition & const Size(1, 1),
    Offset.zero & overlay.size,
  );

  final action = await showMenu<String>(
    context: context,
    position: relative,
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
    items: [
      const PopupMenuItem(
        value: 'play',
        child: _Item(
          icon: Icons.play_arrow,
          label: 'Lire maintenant',
        ),
      ),
      PopupMenuItem(
        value: 'favorite',
        child: _Item(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
        ),
      ),
      const PopupMenuItem(
        value: 'playlist',
        child: _Item(
          icon: Icons.playlist_add,
          label: 'Ajouter à une playlist',
        ),
      ),
      const PopupMenuItem(
        value: 'detail',
        child: _Item(
          icon: Icons.info_outline,
          label: 'Voir la piste',
        ),
      ),
      if (track.album != null && track.album!.trim().isNotEmpty)
        PopupMenuItem(
          value: 'album',
          child: _Item(
            icon: Icons.album_outlined,
            label: 'Voir l\'album « ${track.album} »',
          ),
        ),
    ],
  );

  switch (action) {
    case 'play':
      onPlay();
    case 'favorite':
      try {
        await ref.read(favoritesProvider.notifier).toggle(track);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de modifier le favori.')),
          );
        }
      }
    case 'playlist':
      if (context.mounted) {
        await _showAddToPlaylistSheet(context, ref, track);
      }
    case 'detail':
      if (context.mounted) {
        context.pushNamed(
          RouteNames.trackDetail,
          pathParameters: {'id': track.id},
        );
      }
    case 'album':
      if (context.mounted) {
        await _openAlbum(context, ref, track);
      }
  }
}

Future<void> _openAlbum(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  try {
    final albums = await ref.read(albumsProvider.future);
    String? albumId;
    for (final album in albums) {
      if (album.title == track.album) {
        albumId = album.id;
        break;
      }
    }
    if (albumId != null && context.mounted) {
      context.pushNamed(
        RouteNames.albumDetail,
        pathParameters: {'id': albumId},
      );
    }
  } catch (_) {
    // ignore: album lookup failure is non-fatal
  }
}

Future<void> _showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  List<Playlist> playlists = const [];
  try {
    playlists = await ref.read(playlistsProvider.future);
  } catch (_) {
    // ignore: list may be empty on failure
  }
  if (!context.mounted) return;

  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('Nouvelle playlist'),
            onTap: () => Navigator.of(context).pop('new'),
          ),
          for (final playlist in playlists)
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${playlist.trackCount} pistes'),
              onTap: () => Navigator.of(context).pop(playlist.id),
            ),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  String? playlistId = action;
  if (action == 'new') {
    final name = await _promptPlaylistName(context);
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    try {
      final created = await ref
          .read(playlistsActionsProvider.notifier)
          .create(name.trim());
      playlistId = created.id;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de créer la playlist.')),
        );
      }
      return;
    }
  }

  try {
    await ref
        .read(playlistsActionsProvider.notifier)
        .addTracks(playlistId, [track.id]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajouté à la playlist.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ajouter la piste.')),
      );
    }
  }
}

Future<String?> _promptPlaylistName(BuildContext context) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nouvelle playlist'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom de la playlist'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Créer'),
        ),
      ],
    ),
  );
  controller.dispose();
  return name;
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
