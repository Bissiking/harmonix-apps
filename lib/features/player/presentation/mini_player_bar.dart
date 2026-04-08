import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/color_scheme.dart';
import '../../../shared/widgets/track_artwork.dart';
import '../providers/now_playing_provider.dart';
import '../providers/player_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    return nowPlaying.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();

        final playbackState = ref.watch(playbackStateStreamProvider);
        final isPlaying = playbackState.valueOrNull?.playing ?? false;

        return GestureDetector(
          onTap: () => context.pushNamed('player'),
          child: Container(
            height: 64,
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
                        item.artist ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    final notifier = ref.read(playerProvider.notifier);
                    isPlaying ? notifier.pause() : notifier.play();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
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
