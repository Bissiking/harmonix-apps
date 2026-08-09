import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/features/cast/providers/google_cast_provider.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/widgets/track_artwork.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return nowPlaying.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        final playbackState = ref.watch(playbackStateStreamProvider);
        final cast = ref.watch(googleCastProvider);
        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        final barHeight = isDesktop ? 72.0 : 64.0;
        final useCast = cast.casting;
        final isPlaying =
            useCast ? cast.isPlaying : (playbackState.valueOrNull?.playing ?? false);

        final playerNotifier = ref.read(playerProvider.notifier);
        final castNotifier = ref.read(googleCastProvider.notifier);

        return GestureDetector(
          onTap: () => context.pushNamed('player'),
          child: Container(
            height: barHeight,
            color: HarmonixColors.darkSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TrackArtwork(
                  coverFile: item.extras?['coverFile'] as String?,
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
                        useCast ? 'Cast → ${cast.deviceName}' : (item.artist ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: useCast ? HarmonixColors.accent : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => useCast
                      ? castNotifier.skipToPrevious()
                      : playerNotifier.skipToPrevious(),
                ),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      key: ValueKey(isPlaying),
                    ),
                  ),
                  onPressed: () {
                    if (useCast) {
                      isPlaying ? castNotifier.pause() : castNotifier.play();
                    } else {
                      isPlaying
                          ? playerNotifier.pause()
                          : playerNotifier.play();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => useCast
                      ? castNotifier.skipToNext()
                      : playerNotifier.skipToNext(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
