import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/features/cast/presentation/cast_sheet.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider).valueOrNull;
    final playbackState = ref.watch(playbackStateStreamProvider).valueOrNull;
    final localPosition = ref.watch(playbackPositionProvider).valueOrNull;
    final durationFromPlayer = ref.watch(playbackDurationProvider).valueOrNull;
    final queue =
        ref.watch(playbackQueueProvider).valueOrNull ?? const <MediaItem>[];
    final cast = ref.watch(googleCastProvider);

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
    final isPlaying =
        useCast ? cast.isPlaying : (playbackState?.playing ?? false);
    final position = useCast ? cast.position : (localPosition ?? Duration.zero);
    final duration = useCast
        ? (cast.duration ?? nowPlaying.duration ?? Duration.zero)
        : (durationFromPlayer ?? nowPlaying.duration ?? Duration.zero);
    final shuffle = useCast
        ? false
        : playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeat = useCast
        ? AudioServiceRepeatMode.none
        : playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
    final playerNotifier = ref.read(playerProvider.notifier);
    final castNotifier = ref.read(googleCastProvider.notifier);

    void onPlayPause() {
      if (useCast) {
        isPlaying ? castNotifier.pause() : castNotifier.play();
      } else {
        isPlaying ? playerNotifier.pause() : playerNotifier.play();
      }
    }

    void onSeek(Duration target) {
      if (useCast) {
        castNotifier.seek(target);
      } else {
        playerNotifier.seek(target);
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
        leading: IconButton(
          tooltip: 'Réduire le lecteur',
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Lecteur'),
        actions: [
          IconButton(
            tooltip: useCast
                ? 'Cast vers ${cast.deviceName}'
                : 'Diffuser sur un appareil',
            icon: Icon(
              cast.connected ? Icons.cast_connected : Icons.cast,
              color: useCast ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => showCastSheet(context),
          ),
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
                            playbackState: playbackState,
                            position: position,
                            duration: duration,
                            isPlaying: isPlaying,
                            shuffle: shuffle,
                            repeat: repeat,
                            useCast: useCast,
                            onPlayPause: onPlayPause,
                            onSeek: onSeek,
                            onNext: onNext,
                            onPrevious: onPrevious,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _QueuePanel(
                              queue: queue, currentId: nowPlaying.id),
                        ),
                      ],
                    )
                  : _NowPlayingPanel(
                      nowPlaying: nowPlaying,
                      playbackState: playbackState,
                      position: position,
                      duration: duration,
                      isPlaying: isPlaying,
                      shuffle: shuffle,
                      repeat: repeat,
                      useCast: useCast,
                      onPlayPause: onPlayPause,
                      onSeek: onSeek,
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
    required this.playbackState,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.shuffle,
    required this.repeat,
    required this.useCast,
    required this.onPlayPause,
    required this.onSeek,
    required this.onNext,
    required this.onPrevious,
  });

  final MediaItem nowPlaying;
  final PlaybackState? playbackState;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool shuffle;
  final AudioServiceRepeatMode repeat;
  final bool useCast;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
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
          Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x52000000),
                  offset: Offset(0, 20),
                  blurRadius: 40,
                ),
              ],
            ),
            child: TrackArtwork(
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
          if (useCast) ...[
            const SizedBox(height: 6),
            Text(
              'Diffusion sur ${ref.watch(googleCastProvider).deviceName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ProgressBar(
            progress: position,
            total: duration,
            buffered: useCast ? null : playbackState?.bufferedPosition,
            onSeek: onSeek,
            thumbColor: Theme.of(context).colorScheme.primary,
            progressBarColor: Theme.of(context).colorScheme.primary,
            baseBarColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            bufferedBarColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
            timeLabelTextStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
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
                    : () =>
                        ref.read(playerProvider.notifier).setShuffle(!shuffle),
              ),
              IconButton(
                tooltip: 'Titre précédent',
                iconSize: 36,
                icon: const Icon(Icons.skip_previous),
                onPressed: onPrevious,
              ),
              _PlayPauseButton(
                isPlaying: isPlaying,
                onPressed: onPlayPause,
              ),
              IconButton(
                tooltip: 'Titre suivant',
                iconSize: 36,
                icon: const Icon(Icons.skip_next),
                onPressed: onNext,
              ),
              IconButton(
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
              ),
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

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.queue, required this.currentId});

  final List<MediaItem> queue;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              'À suivre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ],
      ),
    );
  }
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
      child: IconButton(
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
      ),
    );
  }
}
