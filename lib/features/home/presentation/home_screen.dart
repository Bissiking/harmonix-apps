// home_screen.dart
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/catalog/providers/albums_provider.dart';
import 'package:harmonix_apps/features/catalog/presentation/track_list_tile.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/tv/presentation/tv_surfaces.dart';
import 'package:harmonix_apps/shared/widgets/harmonix_logo.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isTelevisionProvider).valueOrNull == true) {
      return const TvCatalogSurface();
    }
    final tracks = ref.watch(tracksProvider);
    final albums = ref.watch(albumsProvider).valueOrNull ?? [];
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            leading: MediaQuery.sizeOf(context).width < 720
                ? Semantics(
                    container: true,
                    child: FlowIconButton(
                        tooltip: 'Navigation',
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            Scaffold.maybeOf(context)?.openDrawer()))
                : null,
            title: const Row(children: [
              HarmonixLogo(size: 28),
              SizedBox(width: 8),
              Flexible(
                  child: Text('Harmonix',
                      maxLines: 1, overflow: TextOverflow.ellipsis))
            ]),
            actions: [
              Semantics(
                  container: true,
                  child: FlowIconButton(
                      tooltip: 'Recherche',
                      icon: const Icon(Icons.search),
                      onPressed: () => context.go('/search'))),
              Semantics(
                  container: true,
                  child: FlowIconButton(
                      tooltip: 'Profil',
                      icon: const Icon(Icons.person_outline),
                      onPressed: () => context.go('/settings')))
            ]),
        body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tracksProvider);
              ref.invalidate(albumsProvider);
              await ref.read(tracksProvider.future);
            },
            child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      sliver: SliverToBoxAdapter(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Retrouve ton Flow.',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text('Ta bibliothèque, ton rythme.',
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            Wrap(spacing: 12, runSpacing: 12, children: [
                              FilledButton.tonalIcon(
                                  onPressed: () => context.go('/library'),
                                  icon:
                                      const Icon(Icons.library_music_outlined),
                                  label: const Text('Ma bibliothèque')),
                              OutlinedButton.icon(
                                  onPressed: () => context.go('/downloads'),
                                  icon: const Icon(Icons.offline_pin_outlined),
                                  label: const Text('Hors connexion')),
                              OutlinedButton.icon(
                                  onPressed: () => context.go('/night'),
                                  icon: const Icon(Icons.nightlight_outlined),
                                  label: const Text('Harmonix Night')),
                            ]),
                          ]))),
                  if (albums.isNotEmpty)
                    SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 0, 24),
                        sliver: SliverToBoxAdapter(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Tes albums',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 12),
                              SizedBox(
                                  height: 232,
                                  child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: albums.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, i) => SizedBox(
                                          width: 160,
                                          child: FlowFocusTile(
                                              onPressed: () => context.push(
                                                  '/catalog/album/${albums[i].id}'),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TrackArtwork(
                                                        coverFile:
                                                            albums[i].coverFile,
                                                        coverUrl:
                                                            albums[i].coverUrl,
                                                        size: 138),
                                                    const SizedBox(height: 10),
                                                    Text(albums[i].title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium),
                                                  ]))))),
                            ]))),
                  const SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                      sliver: SliverToBoxAdapter(
                          child: Text('Dans ta bibliothèque',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)))),
                  tracks.when(
                      loading: () => const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(32),
                              child:
                                  Center(child: CircularProgressIndicator()))),
                      error: (_, __) => SliverToBoxAdapter(
                          child: FlowEmptyState(
                              icon: Icons.cloud_off,
                              title: 'La musique attend ton retour',
                              message:
                                  'Réessaie Sonora ou ouvre les titres disponibles sur cet appareil.',
                              action: FilledButton(
                                  onPressed: () => context.go('/library'),
                                  child:
                                      const Text('Ouvrir la bibliothèque')))),
                      data: (items) => items.isEmpty
                          ? const SliverToBoxAdapter(
                              child: FlowEmptyState(
                                  icon: Icons.library_music_outlined,
                                  title: 'Un espace pour ta musique',
                                  message:
                                      'Connecte Sonora ou importe tes fichiers depuis la bibliothèque.'))
                          : SliverList.builder(
                              itemCount: items.length > 20 ? 20 : items.length,
                              itemBuilder: (context, i) => TrackListTile(
                                  track: items[i],
                                  onTap: () => runFlowAction(
                                      context,
                                      () =>
                                          ref.read(playerProvider.notifier).playFromQueue(items, i))))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                  onPressed: () => context.go('/library'),
                                  icon: const Icon(Icons.arrow_forward),
                                  label:
                                      const Text('Toute ma bibliothèque'))))),
                ])));
  }
}
