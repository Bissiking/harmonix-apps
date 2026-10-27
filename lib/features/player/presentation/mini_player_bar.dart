import 'package:audio_service/audio_service.dart';
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/audio/playback_modes.dart';
import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';

// Keep each tooltip anchor in its own semantics node (Flutter #182444).
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return nowPlaying.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        final localPlaying = ref.watch(playbackStateStreamProvider
            .select((state) => state.valueOrNull?.playing ?? false));
        final canSkip = ref.watch(playerNavigationProvider
            .select((state) => (
                  next: state.valueOrNull?.$1 ?? false,
                  previous: state.valueOrNull?.$2 ?? false,
                )));
        final modes = ref.watch(playbackStateStreamProvider
            .select((state) => (
                  shuffle: state.valueOrNull?.shuffleMode ==
                      AudioServiceShuffleMode.all,
                  repeat: state.valueOrNull?.repeatMode ??
                      AudioServiceRepeatMode.none,
                )));
        final cast = ref.watch(googleCastProvider.select((state) => (
              casting: state.casting,
              isPlaying: state.isPlaying,
              deviceName: state.deviceName,
            )));
        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        // Phone widths keep the three transport controls only; wider layouts
        // also carry the Aléatoire / Boucle toggles.
        final showModes = ResponsiveBreakpoints.isTablet(context);
        final barHeight = isDesktop ? 72.0 : 64.0;
        final useCast = cast.casting;
        final isPlaying = useCast ? cast.isPlaying : localPlaying;

        final playerNotifier = ref.read(playerProvider.notifier);
        final castNotifier = ref.read(googleCastProvider.notifier);

        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => context.goNamed('player'),
            child: Container(
              constraints: BoxConstraints(minHeight: barHeight),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.07),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  children: [
                    TrackArtwork(
                      trackId: item.id,
                      coverFile: item.extras?['coverFile'] as String?,
                      coverUrl: item.extras?['coverUrl'] as String?,
                      size: 44,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            useCast
                                ? 'Cast → ${cast.deviceName}'
                                : (item.artist ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: useCast
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.58),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showModes)
                      Semantics(
                          container: true,
                          child: FlowIconButton(
                            tooltip: modes.shuffle
                                ? 'Désactiver la lecture aléatoire'
                                : 'Activer la lecture aléatoire',
                            icon: Icon(
                              Icons.shuffle,
                              color: modes.shuffle
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.58),
                            ),
                            onPressed: useCast
                                ? null
                                : () =>
                                    playerNotifier.setShuffle(!modes.shuffle),
                          )),
                    Semantics(
                        container: true,
                        child: FlowIconButton(
                          tooltip: 'Titre précédent',
                          icon: const Icon(Icons.skip_previous),
                          onPressed: !useCast && !canSkip.previous
                              ? null
                              : () => useCast
                                  ? castNotifier.skipToPrevious()
                                  : playerNotifier.skipToPrevious(),
                        )),
                    Semantics(
                        container: true,
                        child: FlowIconButton.filled(
                          tooltip: isPlaying ? 'Mettre en pause' : 'Lire',
                          icon: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              key: ValueKey(isPlaying),
                            ),
                          ),
                          onPressed: () {
                            if (useCast) {
                              isPlaying
                                  ? castNotifier.pause()
                                  : castNotifier.play();
                            } else {
                              isPlaying
                                  ? playerNotifier.pause()
                                  : playerNotifier.play();
                            }
                          },
                        )),
                    Semantics(
                        container: true,
                        child: FlowIconButton(
                          tooltip: 'Titre suivant',
                          icon: const Icon(Icons.skip_next),
                            onPressed: !useCast && !canSkip.next
                                ? null
                                : () => useCast
                                    ? castNotifier.skipToNext()
                                    : playerNotifier.skipToNext(),
                        )),
                    if (showModes)
                      Semantics(
                          container: true,
                          child: FlowIconButton(
                            tooltip: modes.repeat ==
                                    AudioServiceRepeatMode.none
                                ? 'Activer la répétition'
                                : 'Changer le mode de répétition',
                            icon: Icon(
                              repeatModeIcon(modes.repeat),
                              color: modes.repeat != AudioServiceRepeatMode.none
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.58),
                            ),
                            onPressed: useCast
                                ? null
                                : () => playerNotifier
                                    .setRepeat(nextRepeatMode(modes.repeat)),
                          )),
                  ],
                ),
                const SizedBox(height: 4),
                const _MiniPlayerProgress(),
              ]),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Position ticks only rebuild the progress strip, not artwork or tooltips.
class _MiniPlayerProgress extends ConsumerWidget {
  const _MiniPlayerProgress();

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
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Semantics(
      container: true,
      label: 'Progression du titre',
      value: '${(progress * 100).round()} %',
      excludeSemantics: true,
      child: LinearProgressIndicator(value: progress, minHeight: 2),
    );
  }
}
