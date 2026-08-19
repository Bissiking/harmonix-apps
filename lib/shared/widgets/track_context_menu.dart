import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/navigation/route_names.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/library/providers/favorites_provider.dart';

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
