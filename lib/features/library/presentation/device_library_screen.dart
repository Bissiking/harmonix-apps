// device_library_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/data/mixed_playlist_sync.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';

class DeviceLibraryScreen extends ConsumerStatefulWidget {
  const DeviceLibraryScreen({super.key});
  @override
  ConsumerState<DeviceLibraryScreen> createState() =>
      _DeviceLibraryScreenState();
}

class _DeviceLibraryScreenState extends ConsumerState<DeviceLibraryScreen> {
  String filter = 'Tout';
  bool importing = false;
  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final files = ref.watch(deviceTracksProvider).valueOrNull ?? [];
    final personal = {
      for (final f in files.where((f) => f.source == MusicSource.personal))
        f.track.id
    };
    final downloaded = {
      for (final f in files.where((f) => f.source == MusicSource.downloaded))
        f.track.id
    };
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in [
              'Tout',
              'Sonora',
              'Cet appareil',
              'Téléchargé'
            ])
              ChoiceChip(
                  label: Text(option),
                  selected: filter == option,
                  onSelected: (_) => setState(() => filter = option)),
            if (supportsDeviceFiles)
              FilledButton.tonalIcon(
                  onPressed: importing ? null : () => _import(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                      importing ? 'Importation…' : 'Importer des fichiers')),
            if (supportsDeviceFiles)
              OutlinedButton.icon(
                  onPressed: importing ? null : () => _import(folder: true),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Importer un dossier')),
          ])),
      if (!supportsDeviceFiles)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                'Les fichiers personnels et téléchargements persistants sont disponibles dans l’application native.')),
      Expanded(
          child: tracks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => FlowEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Catalogue indisponible',
                  message:
                      'Passe hors connexion pour retrouver les titres de cet appareil.',
                  action: FilledButton(
                      onPressed: () => ref.invalidate(tracksProvider),
                      child: const Text('Réessayer'))),
              data: (all) {
                final filtered = all
                    .where((track) => switch (filter) {
                          'Sonora' => !personal.contains(track.id),
                          'Cet appareil' => personal.contains(track.id),
                          'Téléchargé' => downloaded.contains(track.id),
                          _ => true,
                        })
                    .toList()
                  ..sort((a, b) =>
                      a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                if (filtered.isEmpty) {
                  return const FlowEmptyState(
                      icon: Icons.library_music_outlined,
                      title: 'Ta musique, réunie ici',
                      message:
                          'Importe tes fichiers ou retrouve ton catalogue Sonora.');
                }
                return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => TrackListTile(
                        track: filtered[i],
                        onTap: () => runFlowAction(
                            context,
                            () => ref
                                .read(playerProvider.notifier)
                                .playFromQueue(filtered, i))));
              })),
    ]);
  }

  Future<void> _import({bool folder = false}) async {
    setState(() => importing = true);
    await runFlowAction(context, () async {
      final library = await ref.read(deviceLibraryProvider.future);
      final files = await pickAudioFiles(library.store.scope, folder: folder);
      for (final file in files) {
        await library.saveFile(file);
      }
      ref.invalidate(deviceTracksProvider);
      ref.read(libraryRevisionProvider.notifier).state++;
      if (mounted && files.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${files.length} fichiers indexés. Les doublons identiques sont réunis.')));
      }
    });
    if (mounted) setState(() => importing = false);
  }
}

class DevicePlaylistsTab extends ConsumerWidget {
  const DevicePlaylistsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(mixedPlaylistsProvider);
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text(
                'Réunis Sonora et tes fichiers personnels. La synchronisation partage la composition, jamais les fichiers audio.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: ref.watch(mixedSyncBusyProvider)
                    ? null
                    : ref.read(mixedSyncActionProvider),
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser avec Sonora')),
            if (ref.watch(mixedSyncStatusProvider) != null)
              Text(ref.watch(mixedSyncStatusProvider)!),
            for (final conflict
                in ref.watch(playlistConflictsProvider).valueOrNull ??
                    <Map<String, dynamic>>[])
              TextButton(
                  onPressed: () => runFlowAction(context, () async {
                        final sync = MixedPlaylistSync(
                            await ref.read(deviceLibraryProvider.future),
                            ref.read(dioProvider));
                        await sync.preserveLocalAndAcceptRemote(
                            conflict['id'] as String);
                        ref.invalidate(playlistConflictsProvider);
                        ref.invalidate(mixedPlaylistsProvider);
                      }),
                  child: Text(
                      'Conserver ma copie et importer la version distante : ${conflict["name"] ?? conflict["id"]}')),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: () async {
                  final name = await promptPlaylistName(context);
                  if (name == null || !context.mounted) return;
                  await runFlowAction(context, () async {
                    final library =
                        await ref.read(deviceLibraryProvider.future);
                    final playlist = await library.createPlaylist(name);
                    ref.invalidate(mixedPlaylistsProvider);
                    if (context.mounted) {
                      await context.push('/library/mixed/${playlist.id}');
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une playlist mixte')),
          ])),
      Expanded(
          child: playlists.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const FlowEmptyState(
                  icon: Icons.error_outline,
                  title: 'Stockage indisponible',
                  message: 'Réessaie après avoir libéré de l’espace.'),
              data: (items) => items.isEmpty
                  ? const FlowEmptyState(
                      icon: Icons.queue_music,
                      title: 'Compose ta première playlist',
                      message:
                          'Ajoute des titres Sonora et tes fichiers personnels, même hors connexion.')
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => ListTile(
                          leading: const Icon(Icons.queue_music),
                          title: Text(items[i].name),
                          subtitle: Text(
                              '${items[i].trackIds.length} titres · cet appareil'),
                          onTap: () =>
                              context.push('/library/mixed/${items[i].id}'))))),
    ]);
  }
}

Future<String?> promptPlaylistName(BuildContext context,
    {String initial = ''}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('Nom de la playlist'),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 200,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context, value.trim());
                    }
                  }),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler')),
                FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('Enregistrer'))
              ]));
  // Wait for dialog exit before disposing the controller.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  controller.dispose();
  return result;
}

class DevicePlaylistScreen extends ConsumerWidget {
  const DevicePlaylistScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(mixedPlaylistsProvider).valueOrNull ?? [];
    final matches = playlists.where((p) => p.id == id);
    if (matches.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final playlist = matches.first;
    final tracks = ref.watch(playlistTrackIndexProvider).valueOrNull ?? [];
    final byId = {for (final track in tracks) track.id: track};
    final deviceIds = (ref.watch(deviceTracksProvider).valueOrNull ?? [])
        .map((f) => f.track.id)
        .toSet();
    Future<void> edit(MixedPlaylist next) => runFlowAction(context, () async {
          final library = await ref.read(deviceLibraryProvider.future);
          await library.savePlaylist(next, baseRevision: playlist.revision);
          ref.invalidate(mixedPlaylistsProvider);
        });
    final playable =
        playlist.trackIds.map((id) => byId[id]).whereType<Track>().toList();
    return Scaffold(
        appBar: AppBar(title: Text(playlist.name), actions: [
          FlowIconButton(
              tooltip: 'Renommer',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final name =
                    await promptPlaylistName(context, initial: playlist.name);
                if (name != null) await edit(playlist.edit(name: name));
              }),
          FlowIconButton(
              tooltip: 'Supprimer la playlist',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Supprimer cette playlist ?'),
                            content: const Text(
                                'Les fichiers musicaux seront conservés.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'))
                            ]));
                if (confirmed != true || !context.mounted) return;
                await runFlowAction(context, () async {
                  final library = await ref.read(deviceLibraryProvider.future);
                  await library.store
                      .put('playlist_tombstones', id, playlist.edit().toJson());
                  await library.store.remove('mixed_playlists', id);
                  ref.invalidate(mixedPlaylistsProvider);
                  if (context.mounted) Navigator.pop(context);
                });
              }),
        ]),
        body: Column(children: [
          if (supportsDeviceFiles)
            SwitchListTile(
                title: const Text('Maintenir hors connexion sur cet appareil'),
                subtitle: const Text(
                    'Téléchargements automatiques des titres Sonora, sur toute connexion. Les fichiers personnels restent locaux.'),
                value: playlist.keepOffline,
                onChanged: (value) => edit(playlist.edit(keepOffline: value))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(spacing: 12, runSpacing: 8, children: [
                if (supportsDeviceFiles)
                  OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Retrouver un fichier'),
                      onPressed: () => runFlowAction(context, () async {
                            final library =
                                await ref.read(deviceLibraryProvider.future);
                            final files =
                                await pickAudioFiles(library.store.scope);
                            for (final file in files) {
                              await library.saveFile(file);
                            }
                            ref.invalidate(deviceTracksProvider);
                            ref.read(libraryRevisionProvider.notifier).state++;
                          })),
                FilledButton.icon(
                    onPressed: playable.isEmpty
                        ? null
                        : () => runFlowAction(
                            context,
                            () => ref
                                .read(playerProvider.notifier)
                                .playFromQueue(playable, 0)),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Lire')),
                OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                                  title: const Text('Ajouter un titre'),
                                  children: [
                                    for (final track in tracks.where((t) =>
                                        !playlist.trackIds.contains(t.id)))
                                      SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, track.id),
                                          child: Text(
                                              '${track.title} — ${track.artist}'))
                                  ]));
                      if (selected != null) {
                        await edit(playlist
                            .edit(trackIds: [...playlist.trackIds, selected]));
                      }
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Ajouter')),
                if (supportsDeviceFiles)
                  OutlinedButton.icon(
                      onPressed: playable.isEmpty
                          ? null
                          : () => runFlowAction(context, () async {
                                for (final track in playable
                                    .where((t) => !isPersonalTrack(t.id))) {
                                  await ref
                                      .read(playerProvider.notifier)
                                      .downloadTrack(track);
                                }
                              }),
                      icon: const Icon(Icons.download),
                      label: const Text('Télécharger')),
              ])),
          Expanded(
              child: ReorderableListView.builder(
                  itemCount: playlist.trackIds.length,
                  onReorder: (oldIndex, newIndex) {
                    final ids = [...playlist.trackIds];
                    if (newIndex > oldIndex) newIndex--;
                    ids.insert(newIndex, ids.removeAt(oldIndex));
                    edit(playlist.edit(trackIds: ids));
                  },
                  itemBuilder: (context, i) {
                    final track = byId[playlist.trackIds[i]];
                    final missingLocal =
                        isPersonalTrack(playlist.trackIds[i]) &&
                            !deviceIds.contains(playlist.trackIds[i]);
                    return ListTile(
                        key: ValueKey(playlist.trackIds[i]),
                        title: Text(track?.title ??
                            'Titre indisponible sur cet appareil'),
                        subtitle: Text(missingLocal
                            ? 'Absent de cet appareil · réimporte une copie identique.'
                            : track?.artist ??
                                'Titre indisponible. Sa référence est conservée.'),
                        onTap: track == null || missingLocal
                            ? null
                            : () => runFlowAction(
                                context,
                                () => ref
                                    .read(playerProvider.notifier)
                                    .playTrack(track)),
                        trailing: Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: FlowIconButton(
                                tooltip: 'Retirer le titre',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => edit(playlist.edit(
                                    trackIds: [...playlist.trackIds]
                                      ..removeAt(i))))));
                  })),
        ]));
  }
}
