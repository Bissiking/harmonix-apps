import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/providers/playlists_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistDetailProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
        actions: [
          IconButton(
            tooltip: 'Renommer',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, ref),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: playlist,
        onRetry: () => ref.invalidate(playlistDetailProvider(playlistId)),
        data: (p) {
          final tracks = p.tracks;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${tracks.length} piste${tracks.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: tracks.isEmpty
                          ? null
                          : () => ref
                              .read(playerProvider.notifier)
                              .playFromQueue(tracks, 0),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lire'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addTracks(context, ref, tracks),
                      icon: const Icon(Icons.library_music_outlined),
                      label: const Text('Ajouter des titres'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tracks.isEmpty)
                const Center(child: Text('Cette playlist est vide.')),
              for (var i = 0; i < tracks.length; i++)
                TrackListTile(
                  track: tracks[i],
                  onTap: () => ref
                      .read(playerProvider.notifier)
                      .playFromQueue(tracks, i),
                  onRemove: () => _removeTrack(context, ref, tracks[i].id),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final current = ref.read(playlistDetailProvider(playlistId)).valueOrNull;
    if (current == null) return;
    final controller = TextEditingController(text: current.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      await ref.read(playlistsActionsProvider.notifier).rename(playlistId, name);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de renommer la playlist.')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette playlist ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(playlistsActionsProvider.notifier).delete(playlistId);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer la playlist.')),
        );
      }
    }
  }

  Future<void> _removeTrack(
    BuildContext context,
    WidgetRef ref,
    String trackId,
  ) async {
    try {
      await ref
          .read(playlistsActionsProvider.notifier)
          .removeTrack(playlistId, trackId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de retirer la piste.'),
          ),
        );
      }
    }
  }

  Future<void> _addTracks(
    BuildContext context,
    WidgetRef ref,
    List<Track> currentTracks,
  ) async {
    final allTracks = await ref.read(tracksProvider.future);
    if (!context.mounted) return;
    final currentIds = currentTracks.map((t) => t.id).toSet();
    final selected = <String>{};

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter des titres'),
        content: SizedBox(
          width: 480,
          height: 420,
          child: StatefulBuilder(
            builder: (context, setState) {
              final candidates =
                  allTracks.where((t) => !currentIds.contains(t.id)).toList();
              return candidates.isEmpty
                  ? const Center(
                      child: Text('Tous les titres sont déjà dans la playlist.'),
                    )
                  : ListView.builder(
                      itemCount: candidates.length,
                      itemBuilder: (_, i) {
                        final track = candidates[i];
                        final checked = selected.contains(track.id);
                        return CheckboxListTile(
                          dense: true,
                          value: checked,
                          title: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              selected.add(track.id);
                            } else {
                              selected.remove(track.id);
                            }
                          }),
                        );
                      },
                    );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (selected.isEmpty || !context.mounted) return;
    try {
      await ref
          .read(playlistsActionsProvider.notifier)
          .addTracks(playlistId, selected.toList());
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ajouter les titres.'),
          ),
        );
      }
    }
  }
}