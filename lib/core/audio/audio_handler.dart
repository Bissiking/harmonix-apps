import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class HarmonixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  HarmonixAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // ------------------------------------------------------------------ Queue

  Future<void> playFromTrackId(
    String trackId,
    String streamUrl, {
    MediaItem? mediaItem,
  }) async {
    final item = mediaItem ??
        MediaItem(
          id: trackId,
          title: 'Unknown',
        );

    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(streamUrl),
        tag: item,
      ),
    );
    await _player.play();
  }

  Future<void> loadQueue(
    List<MediaItem> items,
    List<String> streamUrls, {
    int initialIndex = 0,
  }) async {
    assert(items.length == streamUrls.length);

    queue.add(items);
    mediaItem.add(items.isNotEmpty ? items[initialIndex] : null);

    final sources = List.generate(
      items.length,
      (i) => AudioSource.uri(Uri.parse(streamUrls[i]), tag: items[i]),
    );

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initialIndex,
    );
  }

  // --------------------------------------------------- BaseAudioHandler API

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      final idx = _player.currentIndex ?? 0;
      final q = queue.value;
      if (idx < q.length) mediaItem.add(q[idx]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      final idx = _player.currentIndex ?? 0;
      final q = queue.value;
      if (idx < q.length) mediaItem.add(q[idx]);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    final q = queue.value;
    if (index < q.length) mediaItem.add(q[index]);
    await _player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.group ||
      AudioServiceRepeatMode.all =>
        LoopMode.all,
    });
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setVolume':
        await _player.setVolume((extras?['volume'] as num?)?.toDouble() ?? 1.0);
      case 'dispose':
        await _player.dispose();
    }
  }

  // ---------------------------------------------------------- State broadcast

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        repeatMode: switch (_player.loopMode) {
          LoopMode.off => AudioServiceRepeatMode.none,
          LoopMode.one => AudioServiceRepeatMode.one,
          LoopMode.all => AudioServiceRepeatMode.all,
        },
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
