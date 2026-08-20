import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/models/lyrics.dart';
import 'package:harmonix_apps/features/player/providers/lyrics_provider.dart';
import 'package:harmonix_apps/features/player/providers/playback_position_provider.dart';
import 'package:harmonix_apps/shared/widgets/async_value_widget.dart';

class LyricsView extends ConsumerWidget {
  const LyricsView({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = ref.watch(trackLyricsProvider(trackId));

    return AsyncValueWidget(
      value: lyrics,
      onRetry: () => ref.invalidate(trackLyricsProvider(trackId)),
      data: (data) {
        if (!data.hasLyrics) {
          return const Center(child: Text('Paroles indisponibles pour ce titre.'));
        }
        final lines = data.lines;
        if (lines.isEmpty) {
          return const Center(child: Text('Paroles indisponibles pour ce titre.'));
        }
        return data.synced
            ? _SyncedLyrics(trackId: trackId, lines: lines)
            : _PlainLyrics(lines: lines);
      },
    );
  }
}

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.lines});

  final List<LyricLine> lines;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: lines.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          lines[i].text,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  const _SyncedLyrics({required this.trackId, required this.lines});

  final String trackId;
  final List<LyricLine> lines;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  final _controller = ScrollController();
  int _currentIndex = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playbackPositionProvider).valueOrNull;
    final positionMs = position?.inMilliseconds ?? 0;

    var activeIndex = -1;
    for (var i = 0; i < widget.lines.length; i++) {
      if (widget.lines[i].time.inMilliseconds <= positionMs) {
        activeIndex = i;
      } else {
        break;
      }
    }
    if (activeIndex != _currentIndex) {
      _currentIndex = activeIndex;
      _scrollToActive(activeIndex);
    }

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.lines.length,
      itemBuilder: (_, i) {
        final isActive = i == activeIndex;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: isActive
              ? Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )
              : Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              widget.lines[i].text,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  void _scrollToActive(int index) {
    if (index < 0 || !_controller.hasClients) return;
    final target = index.toDouble() * 60.0 - 80.0;
    final maxExtent = _controller.position.maxScrollExtent;
    _controller.animateTo(
      target.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}