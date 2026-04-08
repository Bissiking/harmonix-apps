import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../shared/theme/color_scheme.dart';
import '../../../shared/widgets/track_artwork.dart';
import '../providers/now_playing_provider.dart';
import '../providers/playback_position_provider.dart';
import '../providers/player_provider.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider).valueOrNull;
    final playbackState = ref.watch(playbackStateStreamProvider).valueOrNull;
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final durationFromPlayer =
        ref.watch(playbackDurationProvider).valueOrNull;

    if (nowPlaying == null) {
      return const Scaffold(body: Center(child: Text('Aucune piste en cours')));
    }

    final isPlaying = playbackState?.playing ?? false;
    final duration = durationFromPlayer ??
        nowPlaying.duration ??
        Duration.zero;
    final shuffle =
        playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeat = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;

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
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              TrackArtwork(
                coverFile:
                    nowPlaying.extras?['coverFile'] as String?,
                size: MediaQuery.of(context).size.width - 64,
                borderRadius: 20,
              ),
              const SizedBox(height: 32),
              // Title / artist
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
              ),
              const SizedBox(height: 32),
              // Progress bar
              ProgressBar(
                progress: position ?? Duration.zero,
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
              const SizedBox(height: 24),
              // Controls row
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
                    onPressed: () =>
                        ref.read(playerProvider.notifier).skipToNext(),
                  ),
                  IconButton(
                    icon: Icon(
                      _repeatIcon(repeat),
                      color: repeat != AudioServiceRepeatMode.none
                          ? HarmonixColors.accent
                          : Colors.white54,
                    ),
                    onPressed: () =>
                        ref.read(playerProvider.notifier).setRepeat(
                          _nextRepeat(repeat),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
