import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tracksProvider);
            ref.invalidate(albumsProvider);
            await Future.wait([
              ref.read(tracksProvider.future),
              ref.read(albumsProvider.future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: _Header(
                        onSearch: () => context.go('/search'),
                        onProfile: () => context.go('/settings'),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: tracks.when(
                        loading: () => const _HomeLoading(),
                        error: (error, _) => _HomeError(
                          onRetry: () => ref.invalidate(tracksProvider),
                        ),
                        data: (items) => _HomeContent(
                          tracks: items,
                          albums: albums.valueOrNull ?? const <Album>[],
                          onPlay: (index) => ref
                              .read(playerProvider.notifier)
                              .playFromQueue(items, index),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onProfile});

  final VoidCallback onSearch;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Qu’est-ce qu’on écoute aujourd’hui ?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Rechercher',
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Ouvrir le profil',
          onPressed: onProfile,
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.tracks,
    required this.albums,
    required this.onPlay,
  });

  final List<Track> tracks;
  final List<Album> albums;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyHome();
    }
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final recent = tracks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _FeaturedTrack(
                  track: tracks.first,
                  onPlay: () => onPlay(0),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: _RecentPanel(tracks: recent, onPlay: onPlay),
              ),
            ],
          )
        else ...[
          _FeaturedTrack(track: tracks.first, onPlay: () => onPlay(0)),
          const SizedBox(height: 28),
          _RecentPanel(tracks: recent, onPlay: onPlay),
        ],
        const SizedBox(height: 32),
        Text('Explorer par envie',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const _QuickActions(),
        if (albums.isNotEmpty) ...[
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Albums à découvrir',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/catalog'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: albums.take(8).length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _AlbumCard(album: albums[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedTrack extends StatelessWidget {
  const _FeaturedTrack({required this.track, required this.onPlay});

  final Track track;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final minimumHeight = 280.0 + ((textScale - 1).clamp(0.0, 1.0) * 160);
    return SizedBox(
      height: minimumHeight,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 14),
              blurRadius: 30,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.68,
                child: TrackArtwork(
                  coverFile: track.coverFile,
                  coverUrl: track.coverUrl,
                  size: 300,
                  borderRadius: 0,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.surfaceContainerHigh,
                    colors.surfaceContainerHigh.withValues(alpha: 0.72),
                    colors.surfaceContainerHigh.withValues(alpha: 0),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colors.secondary),
                  const SizedBox(height: 16),
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(track.artist,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Écouter maintenant'),
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

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.tracks, required this.onPlay});

  final List<Track> tracks;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ajouts récents', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (var index = 0; index < tracks.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                minTileHeight: 52,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: TrackArtwork(
                  coverFile: tracks[index].coverFile,
                  coverUrl: tracks[index].coverUrl,
                  size: 42,
                  borderRadius: 9,
                ),
                title: Text(
                  tracks[index].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  tracks[index].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Lire ${tracks[index].title}',
                  onPressed: () => onPlay(index),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
                onTap: () => onPlay(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (
        'Favoris',
        Icons.favorite_outline_rounded,
        '/library',
        Color(0xFFA78BFA)
      ),
      ('Albums', Icons.album_outlined, '/catalog', Color(0xFF67D7F0)),
      ('Recherche', Icons.travel_explore_rounded, '/search', Color(0xFF66D6A8)),
      ('Rift', Icons.groups_2_outlined, '/rift', Color(0xFFFFB85C)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.go(action.$3),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(action.$2, color: action.$4),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            action.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/catalog/album/${album.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrackArtwork(
              coverFile: album.coverFile,
              coverUrl: album.coverUrl,
              size: 142,
              borderRadius: 14,
            ),
            const SizedBox(height: 8),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text('Le catalogue est momentanément indisponible.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
              onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 360,
      child: Center(child: Text('Aucune musique publique pour le moment.')),
    );
  }
}
