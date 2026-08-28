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
      if (state == ProcessingState.completed && !_isSkipping) {
        _isSkipping = true;
        skipToNext().whenComplete(() => _isSkipping = false);
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  PlaybackEvent? _lastPlaybackEvent;
  DateTime _lastPlaybackLog = DateTime.fromMillisecondsSinceEpoch(0);
  ConcatenatingAudioSource? _incrementalSource;
  bool _isSkipping = false;
  Future<List<MediaItem>> Function()? _androidAutoCatalogLoader;
  Future<List<MediaItem>> Function(String query)? _androidAutoSearch;
  Future<void> Function(String mediaId)? _androidAutoPlayFromMediaId;

  /// Throttle for desktop: prevent _broadcastState from firing more than once
  /// per [_broadcastMinInterval]. On mobile AudioService buffers events; on
  /// desktop we use the raw handler so we must throttle ourselves.
  DateTime _lastBroadcast = DateTime.fromMillisecondsSinceEpoch(0);
  ProcessingState _lastBroadcastProcessingState = ProcessingState.idle;
  bool _lastBroadcastPlaying = false;
  static const Duration _broadcastMinInterval = Duration(milliseconds: 200);

  AudioPlayer get player => _player;

  /// Connects Android Auto's browse/search commands to the app repositories.
  /// The callbacks are installed once Riverpod is ready in [AutoBridge].
  void configureAndroidAuto({
    required Future<List<MediaItem>> Function() loadCatalog,
    required Future<List<MediaItem>> Function(String query) search,
    required Future<void> Function(String mediaId) playFromMediaId,
  }) {
    _androidAutoCatalogLoader = loadCatalog;
    _androidAutoSearch = search;
    _androidAutoPlayFromMediaId = playFromMediaId;
  }

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

    mediaItem.add(item);
    _incrementalSource = null;
    assert(() {
      debugPrint(
        'AudioHandler.playFromTrackId url=$streamUrl headers=${headers?.keys.toList()}',
      );
      return true;
    }());
    await _setAudioSourceWithRetry(
      () => _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: item,
          headers: headers,
        ),
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

    _incrementalSource = null;
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

    await _setAudioSourceWithRetry(
      () => _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: initialIndex,
      ),
    );
  }

  Future<void> loadQueueIncremental(
    List<MediaItem> items,
    String initialUrl, {
    required int initialIndex,
  }) async {
    final item = items[initialIndex];
    queue.add(items);
    mediaItem.add(item);

    _incrementalSource = ConcatenatingAudioSource(
      children: [
        AudioSource.uri(Uri.parse(initialUrl), tag: item),
      ],
    );
    await _setAudioSourceWithRetry(
      () => _player.setAudioSource(_incrementalSource!, initialIndex: 0),
    );
  }

  Future<void> appendQueueItem(String url, MediaItem item) async {
    final source = _incrementalSource;
    if (source == null) return;
    await source.add(AudioSource.uri(Uri.parse(url), tag: item));
  }

  // --------------------------------------------------- BaseAudioHandler API

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final loader = _androidAutoCatalogLoader;
    if (loader == null) return queue.value;
    try {
      return await loader();
    } catch (_) {
      return queue.value;
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return getChildren('root');
    final searchCatalog = _androidAutoSearch;
    if (searchCatalog == null) {
      final lowerQuery = normalizedQuery.toLowerCase();
      return queue.value
          .where(
            (item) =>
                item.title.toLowerCase().contains(lowerQuery) ||
                (item.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
                (item.album?.toLowerCase().contains(lowerQuery) ?? false),
          )
          .toList();
    }
    try {
      return await searchCatalog(normalizedQuery);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    for (final item in queue.value) {
      if (item.id == mediaId) return item;
    }
    final catalog = await getChildren('root');
    for (final item in catalog) {
      if (item.id == mediaId) return item;
    }
    return null;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final playTrack = _androidAutoPlayFromMediaId;
    if (playTrack != null) {
      await playTrack(mediaId);
      return;
    }

    final index = queue.value.indexWhere((item) => item.id == mediaId);
    if (index >= 0) await skipToQueueItem(index);
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final results = await search(query, extras);
    if (results.isNotEmpty) {
      await playFromMediaId(results.first.id, extras);
    }
  }

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
      // mediaItem is already updated by the currentIndexStream listener –
      // no need to push it again here (avoids a redundant rebuild storm
      // especially on desktop where there is no AudioService buffering).
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
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
    // Throttle on desktop to avoid flooding the UI isolate with position
    // updates (~4-5 Hz).  Important state changes (processingState, playing)
    // are always broadcast immediately.
    if (!kIsWeb) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastBroadcast);
      final sameProcessingState =
          _player.processingState == _lastBroadcastProcessingState;
      final samePlaying = _player.playing == _lastBroadcastPlaying;
      if (elapsed < _broadcastMinInterval &&
          sameProcessingState &&
          samePlaying) {
        return;
      }
      _lastBroadcast = now;
      _lastBroadcastProcessingState = _player.processingState;
      _lastBroadcastPlaying = _player.playing;
    }

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

  Future<void> _setAudioSourceWithRetry(
    Future<Duration?> Function() action, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await action();
        return;
      } catch (error) {
        lastError = error;
        if (attempt == maxAttempts) break;
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
    throw lastError ?? StateError('Unable to set audio source');
  }
}
