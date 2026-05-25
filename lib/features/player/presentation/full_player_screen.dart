import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:harmonix_apps/core/utils/duration_formatter.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider).valueOrNull;
    final playbackState = ref.watch(playbackStateStreamProvider).valueOrNull;
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final durationFromPlayer = ref.watch(playbackDurationProvider).valueOrNull;
    final queue =
        ref.watch(playbackQueueProvider).valueOrNull ?? const <MediaItem>[];

    if (nowPlaying == null) {
      return const Scaffold(body: Center(child: Text('Aucune piste en cours')));
    }

    final isPlaying = playbackState?.playing ?? false;
    final duration = durationFromPlayer ?? nowPlaying.duration ?? Duration.zero;
    final shuffle = playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeat = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
    final isWide = ResponsiveBreakpoints.isTablet(context) &&
        ResponsiveBreakpoints.isLandscape(context);

    return Scaffold(
      backgroundColor: HarmonixColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('En cours de lecture'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _NowPlayingPanel(
                        nowPlaying: nowPlaying,
                        playbackState: playbackState,
                        position: position ?? Duration.zero,
                        duration: duration,
                        isPlaying: isPlaying,
                        shuffle: shuffle,
                        repeat: repeat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child:
                          _QueuePanel(queue: queue, currentId: nowPlaying.id),
                    ),
                  ],
                )
              : _NowPlayingPanel(
                  nowPlaying: nowPlaying,
                  playbackState: playbackState,
                  position: position ?? Duration.zero,
                  duration: duration,
                  isPlaying: isPlaying,
                  shuffle: shuffle,
                  repeat: repeat,
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
  });

  final MediaItem nowPlaying;
  final PlaybackState? playbackState;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool shuffle;
  final AudioServiceRepeatMode repeat;

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
          TrackArtwork(
            coverFile: nowPlaying.extras?['coverFile'] as String?,
            size: artSize,
            borderRadius: 20,
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
          const SizedBox(height: 20),
          ProgressBar(
            progress: position,
            total: duration,
            buffered: playbackState?.bufferedPosition,
            onSeek: (d) => ref.read(playerProvider.notifier).seek(d),
            thumbColor: HarmonixColors.accent,
            progressBarColor: HarmonixColors.accent,
            baseBarColor: Colors.white12,
            bufferedBarColor: Colors.white24,
            timeLabelTextStyle:
                const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: shuffle ? HarmonixColors.accent : Colors.white54,
                ),
                onPressed: () =>
                    ref.read(playerProvider.notifier).setShuffle(!shuffle),
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_previous),
                onPressed: () =>
                    ref.read(playerProvider.notifier).skipToPrevious(),
              ),
              _PlayPauseButton(isPlaying: isPlaying),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next),
                onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
              ),
              IconButton(
                icon: Icon(
                  _repeatIcon(repeat),
                  color: repeat != AudioServiceRepeatMode.none
                      ? HarmonixColors.accent
                      : Colors.white54,
                ),
                onPressed: () => ref
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child:
                Text('Queue', style: Theme.of(context).textTheme.titleMedium),
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
                      ? const Icon(Icons.equalizer,
                          color: HarmonixColors.accent)
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

class _PlayPauseButton extends ConsumerWidget {
  const _PlayPauseButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: HarmonixColors.accent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 40,
        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        color: Colors.white,
        onPressed: () {
          final notifier = ref.read(playerProvider.notifier);
          isPlaying ? notifier.pause() : notifier.play();
        },
      ),
    );
  }
}
