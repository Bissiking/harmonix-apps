// search_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/library/providers/playlists_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';

import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';
import 'package:harmonix_apps/features/search/data/search_repository.dart';

final _queryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(_queryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchTracksProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Titres, albums, artistes, playlists…',
            border: InputBorder.none,
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                ref.read(_queryProvider.notifier).state = v;
              }
            });
          },
        ),
        actions: [
          if (query.isNotEmpty)
            FlowIconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Effacer la recherche',
              onPressed: () {
                _controller.clear();
                ref.read(_queryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? const Center(
              child: Text('Entrez un terme pour rechercher'),
            )
          : AsyncValueWidget(
              value: results,
              data: (tracks) => _SearchResults(query: query, tracks: tracks),
            ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.tracks});
  final String query;
  final List<Track> tracks;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query.trim().toLowerCase();
    final albums = (ref.watch(albumsProvider).valueOrNull ?? [])
        .where((a) => '${a.title} ${a.artist}'.toLowerCase().contains(q))
        .toList();
    final artists = tracks
        .map((t) => t.artist)
        .where((a) => a.toLowerCase().contains(q))
        .toSet()
        .toList()
      ..sort();
    final remote = (ref.watch(playlistsProvider).valueOrNull ?? [])
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
    final mixed = (ref.watch(mixedPlaylistsProvider).valueOrNull ?? [])
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
    if (tracks.isEmpty &&
        albums.isEmpty &&
        artists.isEmpty &&
        remote.isEmpty &&
        mixed.isEmpty) {
      return const FlowEmptyState(
          icon: Icons.search_off,
          title: 'Aucun résultat',
          message: 'Essaie un autre titre, artiste ou nom de playlist.');
    }
    SliverToBoxAdapter heading(String name) => SliverToBoxAdapter(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(name, style: Theme.of(context).textTheme.titleLarge)));
    return CustomScrollView(slivers: [
      if (artists.isNotEmpty) ...[
        heading('Artistes'),
        SliverList.builder(
            itemCount: artists.length,
            itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(artists[i]),
                onTap: () => context
                    .push('/artists/${Uri.encodeComponent(artists[i])}')))
      ],
      if (albums.isNotEmpty) ...[
        heading('Albums'),
        SliverList.builder(
            itemCount: albums.length,
            itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.album_outlined),
                title: Text(albums[i].title),
                subtitle: Text(albums[i].artist),
                onTap: () => context.push('/catalog/album/${albums[i].id}')))
      ],
      if (mixed.isNotEmpty || remote.isNotEmpty) ...[
        heading('Playlists'),
        SliverList.builder(
            itemCount: mixed.length + remote.length,
            itemBuilder: (context, i) => i < mixed.length
                ? ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(mixed[i].name),
                    subtitle: const Text('Playlist mixte'),
                    onTap: () => context.push('/library/mixed/${mixed[i].id}'))
                : ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(remote[i - mixed.length].name),
                    subtitle: const Text('Sonora'),
                    onTap: () => context.push(
                        '/library/playlist/${remote[i - mixed.length].id}')))
      ],
      if (tracks.isNotEmpty) ...[
        heading('Morceaux'),
        SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) => TrackListTile(
                track: tracks[i],
                onTap: () => runFlowAction(
                    context,
                    () => ref
                        .read(playerProvider.notifier)
                        .playFromQueue(tracks, i))))
      ],
    ]);
  }
}
