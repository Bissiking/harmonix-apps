import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/features/cast/presentation/cast_sheet.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/features/player/presentation/lyrics_view.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/features/tv/presentation/tv_surfaces.dart';
import 'package:harmonix_apps/features/player/providers/dynamic_colors_provider.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/shared/widgets/track_context_menu.dart';
import 'package:harmonix_apps/shared/widgets/flow_components.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isTelevisionProvider).valueOrNull == true) {
      return const TvPlayerSurface();
    }
    final nowPlaying = ref.watch(nowPlayingProvider).valueOrNull;
    final controls = ref.watch(playbackStateStreamProvider.select((state) => (
          playing: state.valueOrNull?.playing ?? false,
          shuffle:
              state.valueOrNull?.shuffleMode == AudioServiceShuffleMode.all,
          repeat: state.valueOrNull?.repeatMode ?? AudioServiceRepeatMode.none,
        )));
    final queue =
        ref.watch(playbackQueueProvider).valueOrNull ?? const <MediaItem>[];
    final cast = ref.watch(googleCastProvider.select((state) => (
          casting: state.casting,
          isPlaying: state.isPlaying,
          connected: state.connected,
          deviceName: state.deviceName,
        )));

    if (nowPlaying == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Lecteur')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.headphones_rounded,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Rien en lecture',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisis un titre pour commencer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/catalog'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Explorer la musique'),
              ),
            ],
          ),
        ),
      );
    }

    final useCast = cast.casting;
    final isPlaying = useCast ? cast.isPlaying : controls.playing;
    final shuffle = useCast ? false : controls.shuffle;
    final repeat = useCast ? AudioServiceRepeatMode.none : controls.repeat;
    final playerNotifier = ref.read(playerProvider.notifier);
    final castNotifier = ref.read(googleCastProvider.notifier);

    void onPlayPause() {
      if (useCast) {
        isPlaying ? castNotifier.pause() : castNotifier.play();
      } else {
        isPlaying ? playerNotifier.pause() : playerNotifier.play();
      }
    }

    void onNext() =>
        useCast ? castNotifier.skipToNext() : playerNotifier.skipToNext();

    void onPrevious() => useCast
        ? castNotifier.skipToPrevious()
        : playerNotifier.skipToPrevious();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Semantics(
            container: true,
            child: FlowIconButton(
              tooltip: 'Réduire le lecteur',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => context.go('/home'),
            )),
        title: const Text('Lecteur'),
        actions: [
          Semantics(
              container: true,
              child: FlowIconButton(
                  tooltip: 'Actions du titre',
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => runFlowAction(context, () async {
                        final track = await ref
                            .read(catalogRepositoryProvider)
                            .getTrack(nowPlaying.id);
                        if (!context.mounted) return;
                        final box = context.findRenderObject() as RenderBox;
                        await showTrackContextMenu(context,
                            tapPosition: box
                                .localToGlobal(Offset(box.size.width - 24, 56)),
                            track: track,
                            ref: ref,
                            onPlay: () =>
                                ref.read(playerProvider.notifier).play());
                      }))),
          if (!(MediaQuery.sizeOf(context).width >= 860))
            Semantics(
                container: true,
                child: FlowIconButton(
                  tooltip: 'Paroles',
                  icon: const Icon(Icons.lyrics_outlined),
                  onPressed: () => showLyricsDialog(context, nowPlaying.id),
                )),
          Semantics(
              container: true,
              child: FlowIconButton(
                tooltip: useCast
                    ? 'Cast vers ${cast.deviceName}'
                    : 'Diffuser sur un appareil',
                icon: Icon(
                  cast.connected ? Icons.cast_connected : Icons.cast,
                  color: useCast ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () => showCastSheet(context),
              )),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _NowPlayingPanel(
                            nowPlaying: nowPlaying,
                            isPlaying: isPlaying,
                            shuffle: shuffle,
                            repeat: repeat,
                            useCast: useCast,
                            onPlayPause: onPlayPause,
                            onNext: onNext,
                            onPrevious: onPrevious,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _SidePanel(
                            trackId: nowPlaying.id,
                            queue: queue,
                            currentId: nowPlaying.id,
                          ),
                        ),
                      ],
                    )
                  : _NowPlayingPanel(
                      nowPlaying: nowPlaying,
                      isPlaying: isPlaying,
                      shuffle: shuffle,
                      repeat: repeat,
                      useCast: useCast,
                      onPlayPause: onPlayPause,
                      onNext: onNext,
                      onPrevious: onPrevious,
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _NowPlayingPanel extends ConsumerWidget {
  const _NowPlayingPanel({
    required this.nowPlaying,
    required this.isPlaying,
    required this.shuffle,
    required this.repeat,
    required this.useCast,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  final MediaItem nowPlaying;
  final bool isPlaying;
  final bool shuffle;
  final AudioServiceRepeatMode repeat;
  final bool useCast;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final maxByWidth = ResponsiveBreakpoints.isDesktop(context)
        ? 380.0
        : (size.width - 64).clamp(180.0, 420.0);
    final maxByHeight = (size.height * 0.38).clamp(160.0, 320.0);
    final artSize = math.min(maxByWidth, maxByHeight);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (ref.watch(playerAmbientProvider).valueOrNull ??
                          Theme.of(context).colorScheme.primary)
                      .withValues(alpha: .18),
                  offset: const Offset(0, 20),
                  blurRadius: 40,
                ),
              ],
            ),
            child: TrackArtwork(
              trackId: nowPlaying.id,
              coverFile: nowPlaying.extras?['coverFile'] as String?,
              coverUrl: nowPlaying.extras?['coverUrl'] as String?,
              size: artSize,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            nowPlaying.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            nowPlaying.artist ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
              switch (nowPlaying.extras?['source']) {
                'personal' => 'Fichier personnel · cet appareil',
                'downloaded' => 'Sonora · téléchargé',
                'cached' => 'Sonora · cache temporaire',
                _ => 'Sonora · streaming',
              },
              style: Theme.of(context).textTheme.bodySmall),
          if (useCast) ...[
            const SizedBox(height: 6),
            Text(
              'Diffusion sur ${ref.watch(googleCastProvider.select((state) => state.deviceName))}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const _PlayerProgress(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Semantics(
                  container: true,
                  child: FlowIconButton(
                    tooltip: shuffle
                        ? 'Désactiver la lecture aléatoire'
                        : 'Activer la lecture aléatoire',
                    icon: Icon(
                      Icons.shuffle,
                      color: shuffle
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.58),
                    ),
                    onPressed: useCast
                        ? null
                        : () => ref
                            .read(playerProvider.notifier)
                            .setShuffle(!shuffle),
                  )),
              Semantics(
                  container: true,
                  child: FlowIconButton(
                    tooltip: 'Titre précédent',
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: onPrevious,
                  )),
              _PlayPauseButton(
                isPlaying: isPlaying,
                onPressed: onPlayPause,
              ),
              Semantics(
                  container: true,
                  child: FlowIconButton(
                    tooltip: 'Titre suivant',
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next),
                    onPressed: onNext,
                  )),
              Semantics(
                  container: true,
                  child: FlowIconButton(
                    tooltip: repeat == AudioServiceRepeatMode.none
                        ? 'Activer la répétition'
                        : 'Changer le mode de répétition',
                    icon: Icon(
                      _repeatIcon(repeat),
                      color: repeat != AudioServiceRepeatMode.none
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.58),
                    ),
                    onPressed: useCast
                        ? null
                        : () => ref
                            .read(playerProvider.notifier)
                            .setRepeat(_nextRepeat(repeat)),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  IconData _repeatIcon(AudioServiceRepeatMode mode) => switch (mode) {
        AudioServiceRepeatMode.one => Icons.repeat_one,
        _ => Icons.repeat,
      };

  AudioServiceRepeatMode _nextRepeat(AudioServiceRepeatMode current) =>
      switch (current) {
        AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
        AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
        _ => AudioServiceRepeatMode.none,
      };
}

class _PlayerProgress extends ConsumerWidget {
  const _PlayerProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cast = ref.watch(googleCastProvider.select((state) => (
          casting: state.casting,
          position: state.position,
          duration: state.duration,
        )));
    final itemDuration = ref
        .watch(nowPlayingProvider.select((item) => item.valueOrNull?.duration));
    final position = cast.casting
        ? cast.position
        : ref.watch(playbackPositionProvider).valueOrNull ?? Duration.zero;
    final duration = cast.casting
        ? cast.duration ?? itemDuration ?? Duration.zero
        : ref.watch(playbackDurationProvider).valueOrNull ??
            itemDuration ??
            Duration.zero;
    final buffered = cast.casting
        ? null
        : ref.watch(playbackStateStreamProvider
            .select((state) => state.valueOrNull?.bufferedPosition));
    final colors = Theme.of(context).colorScheme;
    return ProgressBar(
      progress: position,
      total: duration,
      buffered: buffered,
      onSeek: (target) => cast.casting
          ? ref.read(googleCastProvider.notifier).seek(target)
          : ref.read(playerProvider.notifier).seek(target),
      thumbColor: colors.primary,
      progressBarColor: colors.primary,
      baseBarColor: colors.onSurface.withValues(alpha: 0.12),
      bufferedBarColor: colors.onSurface.withValues(alpha: 0.24),
      timeLabelTextStyle: TextStyle(
        color: colors.onSurface.withValues(alpha: 0.62),
        fontSize: 12,
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.trackId,
    required this.queue,
    required this.currentId,
  });

  final String trackId;
  final List<MediaItem> queue;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TabBar(
                dividerColor: Colors.transparent,
                tabs: [Tab(text: 'À suivre'), Tab(text: 'Paroles')],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                children: [
                  _QueueList(queue: queue, currentId: currentId),
                  LyricsView(trackId: trackId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.queue, required this.currentId});

  final List<MediaItem> queue;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return const Center(child: Text('File vide.'));
    }
    return ListView.builder(
      itemCount: queue.length,
      itemBuilder: (_, i) {
        final item = queue[i];
        final isCurrent = item.id == currentId;
        return ListTile(
          dense: true,
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.artist ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCurrent
              ? Icon(
                  Icons.equalizer,
                  color: Theme.of(context).colorScheme.primary,
                )
              : (item.duration != null
                  ? Text(
                      formatMs(item.duration!.inMilliseconds),
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : null),
        );
      },
    );
  }
}

Future<void> showLyricsDialog(BuildContext context, String trackId) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paroles'),
          leading: Semantics(
              container: true,
              child: FlowIconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )),
        ),
        body: LyricsView(trackId: trackId),
      ),
    ),
  );
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x443E2A80),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Semantics(
          container: true,
          child: FlowIconButton(
            tooltip: isPlaying ? 'Mettre en pause' : 'Lire',
            iconSize: 40,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(isPlaying),
              ),
            ),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: onPressed,
          )),
    );
  }
}
