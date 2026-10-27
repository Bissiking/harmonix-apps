// device_library_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/data/device_files.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/data/mixed_playlist_sync.dart';
import 'package:harmonix_apps/features/library/domain/library_sort.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/night/domain/night_visibility.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';
import 'package:harmonix_apps/shared/widgets/music_collection.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';

class DeviceLibraryScreen extends ConsumerStatefulWidget {
  const DeviceLibraryScreen({super.key});
  @override
  ConsumerState<DeviceLibraryScreen> createState() =>
      _DeviceLibraryScreenState();
}

enum _ImportKind { files, folder }

class _DeviceLibraryScreenState extends ConsumerState<DeviceLibraryScreen> {
  String filter = 'Tout';
  bool importing = false;
  String query = '';
  bool showSearch = false;
  LibrarySort sort = LibrarySort.recent;

  @override
  void initState() {
    super.initState();
    sort =
        librarySortFromName(ref.read(settingsRepositoryProvider).librarySort);
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final addedAt = ref.watch(trackAddedDatesProvider).valueOrNull ?? const {};
    final files = ref.watch(deviceTracksProvider).valueOrNull ?? [];
    final personal = {
      for (final f in files.where((f) => f.source == MusicSource.personal))
        f.track.id
    };
    final downloaded = {
      for (final f in files.where((f) => f.source == MusicSource.downloaded))
        f.track.id
    };
    bool matches(Track track) =>
        '${track.title} ${track.artist} ${track.album ?? ''}'
            .toLowerCase()
            .contains(query.toLowerCase().trim()) &&
        switch (filter) {
          'Sonora' => !personal.contains(track.id),
          'Cet appareil' => personal.contains(track.id),
          'Téléchargé' => downloaded.contains(track.id),
          _ => true,
        };
    final count = tracks.valueOrNull?.where(matches).length;
    final controls = Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PopupMenuButton<LibrarySort>(
                  tooltip: 'Trier la liste',
                  initialValue: sort,
                  onSelected: (value) async {
                    await ref
                        .read(settingsRepositoryProvider)
                        .setLibrarySort(value.name);
                    if (mounted) setState(() => sort = value);
                  },
                  itemBuilder: (context) => [
                    for (final option in LibrarySort.values)
                      PopupMenuItem(
                        value: option,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (option == sort) ...[
                            const Icon(Icons.check, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(option.label),
                        ]),
                      ),
                  ],
                  child: SizedBox(
                      height: 48,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.sort, size: 20),
                            const SizedBox(width: 6),
                            if (MediaQuery.textScalerOf(context).scale(1) <=
                                1.3)
                              Text(sort.label,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                          ]))),
                ),
                IconButton(
                    tooltip: 'Filtrer les titres',
                    icon: Icon(showSearch ? Icons.search_off : Icons.search),
                    onPressed: () => setState(() {
                          showSearch = !showSearch;
                          if (!showSearch) query = '';
                        })),
                if (count != null &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                  Text('$count titre${count == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                if (supportsDeviceFiles) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<_ImportKind>(
                      tooltip: 'Importer',
                      enabled: !importing,
                      onSelected: (kind) =>
                          _import(folder: kind == _ImportKind.folder),
                      itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: _ImportKind.files,
                                child: Text('Fichiers audio…')),
                            PopupMenuItem(
                                value: _ImportKind.folder,
                                child: Text('Dossier entier…')),
                          ],
                      child: SizedBox(
                          height: 48,
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (importing)
                                      const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                    else
                                      const Icon(Icons.add_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    if (MediaQuery.textScalerOf(context)
                                            .scale(1) <=
                                        1.3)
                                      Text(
                                          importing
                                              ? 'Importation…'
                                              : 'Importer',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge),
                                  ])))),
                ],
              ]),
          if (showSearch)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Filtrer par titre, artiste, album'))),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in [
              'Tout',
              'Sonora',
              if (supportsDeviceFiles) 'Cet appareil',
              if (supportsDeviceFiles) 'Téléchargé'
            ])
              ChoiceChip(
                  label: Text(option),
                  selected: filter == option,
                  onSelected: (_) => setState(() => filter = option)),
          ]),
        ]));
    return tracks.when(
        loading: () => const CollectionLoading(),
        error: (_, __) => FlowEmptyState(
            icon: Icons.cloud_off,
            title: 'Catalogue indisponible',
            message:
                'Passe hors connexion pour retrouver les titres de cet appareil.',
            action: FilledButton(
                onPressed: () => ref.invalidate(tracksProvider),
                child: const Text('Réessayer'))),
        data: (all) {
          final filtered =
              sortTracks(all.where(matches).toList(), sort, addedAt);
          if (filtered.isEmpty) {
            final empty = all.isEmpty
                ? const FlowEmptyState(
                    icon: Icons.library_music_outlined,
                    title: 'Ta musique, réunie ici',
                    message:
                        'Importe tes fichiers ou retrouve ton catalogue Sonora.')
                : const FlowEmptyState(
                    icon: Icons.filter_list_off,
                    title: 'Aucun titre dans ce filtre',
                    message: 'Change de source pour retrouver tes titres.');
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: controls),
              SliverFillRemaining(hasScrollBody: false, child: empty),
            ]);
          }
          final hasShelf =
              query.isEmpty && filter == 'Tout' && sort == LibrarySort.recent;
          return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tracksProvider);
                await ref.read(tracksProvider.future);
              },
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: controls),
                if (hasShelf)
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      sliver: SliverToBoxAdapter(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const CollectionHeading(
                                title: 'Derniers ajouts',
                                subtitle: 'De nouvelles écoutes à découvrir.'),
                            MusicCoverShelf(
                                tracks: filtered.take(8).toList(),
                                onPlay: (index) => runFlowAction(
                                    context,
                                    () => ref
                                        .read(playerProvider.notifier)
                                        .playFromQueue(filtered, index))),
                          ]))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    sliver: SliverToBoxAdapter(
                        child: CollectionHeading(
                            title: query.isEmpty
                                ? 'Tous les morceaux'
                                : 'Résultats',
                            subtitle:
                                '${filtered.length} titres · ${sort.label}'))),
                SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => TrackListTile(
                            track: filtered[i],
                            onTap: () => runFlowAction(
                                context,
                                () => ref
                                    .read(playerProvider.notifier)
                                    .playFromQueue(filtered, i))))),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ]));
        });
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
    final nightMetadata =
        ref.watch(nightMetadataProvider).valueOrNull ?? const {};
    final byId = {for (final track in tracks) track.id: track};
    final deviceIds = (ref.watch(deviceTracksProvider).valueOrNull ?? [])
        .map((f) => f.track.id)
        .toSet();
    Future<void> edit(MixedPlaylist next) => runFlowAction(context, () async {
          final library = await ref.read(deviceLibraryProvider.future);
          await library.savePlaylist(next, baseRevision: playlist.revision);
          ref.invalidate(mixedPlaylistsProvider);
        });
    final playable = visibleInLibrary(
        playlist.trackIds.map((id) => byId[id]).whereType<Track>(),
        nightMetadata);
    // Night-only titles are hidden from the rows, but the playlist keeps
    // them: reorder positions are translated back through this list.
    final visibleIds = playlist.trackIds
        .where((id) => !isNightOnly(nightMetadata, id, track: byId[id]))
        .toList();
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
                                    for (final track in visibleInLibrary(
                                        tracks.where((t) =>
                                            !playlist.trackIds.contains(t.id)),
                                        nightMetadata))
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
                  itemCount: visibleIds.length,
                  onReorder: (oldIndex, newIndex) {
                    // Rows are a filtered view of the playlist: translate the
                    // positions back to its own ordering before rewriting it.
                    final movingId = visibleIds[oldIndex];
                    final target =
                        newIndex > oldIndex ? newIndex - 1 : newIndex;
                    final remainingVisible = [...visibleIds]
                      ..removeAt(oldIndex);
                    final afterId = target < remainingVisible.length
                        ? remainingVisible[target]
                        : null;
                    final ids = [...playlist.trackIds]..remove(movingId);
                    final insertAt =
                        afterId == null ? ids.length : ids.indexOf(afterId);
                    ids.insert(insertAt, movingId);
                    edit(playlist.edit(trackIds: ids));
                  },
                  itemBuilder: (context, i) {
                    final id = visibleIds[i];
                    final track = byId[id];
                    final missingLocal =
                        isPersonalTrack(id) && !deviceIds.contains(id);
                    return ListTile(
                        key: ValueKey(id),
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
                                    .playTrack(track, queue: playable)),
                        trailing: Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: FlowIconButton(
                                tooltip: 'Retirer le titre',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => edit(playlist.edit(
                                    trackIds: [...playlist.trackIds]
                                      ..remove(id))))));
                  })),
        ]));
  }
}
