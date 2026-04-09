import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class HarmonixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  HarmonixAudioHandler() {
    _player.playbackEventStream.listen((event) {
      _lastPlaybackEvent = event;
      _broadcastState(event);
      _logPlaybackEvent(event);
    });
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      final q = queue.value;
      if (index >= 0 && index < q.length) {
        mediaItem.add(q[index]);
      }
    });
    _player.loopModeStream.listen((_) => _rebroadcastState());
    _player.shuffleModeEnabledStream.listen((_) => _rebroadcastState());
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  PlaybackEvent? _lastPlaybackEvent;
  DateTime _lastPlaybackLog = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayer get player => _player;

  // ------------------------------------------------------------------ Queue

  Future<void> playFromTrackId(
    String trackId,
    String streamUrl, {
    MediaItem? initialMediaItem,
    Map<String, String>? headers,
  }) async {
    final item = initialMediaItem ??
        MediaItem(
          id: trackId,
          title: 'Unknown',
        );

    this.mediaItem.add(item);
    assert(() {
      debugPrint(
        'AudioHandler.playFromTrackId url=$streamUrl headers=${headers?.keys.toList()}',
      );
      return true;
    }());
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(streamUrl),
        tag: item,
        headers: headers,
      ),
    );
    await _player.play();
  }

  Future<void> loadQueue(
    List<MediaItem> items,
    List<String> streamUrls, {
    int initialIndex = 0,
    Map<String, String>? headers,
  }) async {
    assert(items.length == streamUrls.length);

    queue.add(items);
    mediaItem.add(items.isNotEmpty ? items[initialIndex] : null);

    final sources = List.generate(
      items.length,
      (i) => AudioSource.uri(
        Uri.parse(streamUrls[i]),
        tag: items[i],
        headers: headers,
      ),
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
      await _player.play();
      final idx = _player.currentIndex ?? 0;
      final q = queue.value;
      if (idx < q.length) mediaItem.add(q[idx]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
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
    _rebroadcastState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
    _rebroadcastState();
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

  void _logPlaybackEvent(PlaybackEvent event) {
    assert(() {
      final now = DateTime.now();
      if (now.difference(_lastPlaybackLog).inMilliseconds < 1000) {
        return true;
      }
      _lastPlaybackLog = now;
      debugPrint(
        'AudioState playing=${_player.playing} state=${_player.processingState} '
        'pos=${_player.position.inMilliseconds}ms '
        'buf=${_player.bufferedPosition.inMilliseconds}ms '
        'dur=${_player.duration?.inMilliseconds}ms',
      );
      return true;
    }());
  }

  void _rebroadcastState() {
    final event = _lastPlaybackEvent;
    if (event != null) {
      _broadcastState(event);
    }
  }
}
