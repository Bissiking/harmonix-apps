import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:dart_cast/dart_cast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';

/// Media transformer for Harmonix streams.
///
/// HLS content is proxied as-is (the proxy rewrites the playlist so every
/// segment is fetched with the app's auth headers). Any other format
/// (MP3/AAC/M4A...) is wrapped in a single-segment HLS playlist so the
/// Default Media Receiver can report a correct duration.
class HarmonixCastMediaTransformer implements MediaTransformer {
  const HarmonixCastMediaTransformer();

  @override
  Future<TransformedMedia> transform(CastMedia media, MediaProxy proxy) async {
    final proxyUrl =
        proxy.registerMedia(media.url, headers: media.httpHeaders);

    if (media.type == CastMediaType.hls) {
      return TransformedMedia(
        proxyUrl: proxyUrl,
        effectiveType: CastMediaType.hls,
      );
    }

    final durationSecs = media.duration != null
        ? media.duration!.inMilliseconds / 1000.0
        : null;
    final hlsUrl = proxy.wrapInHlsPlaylist(proxyUrl, duration: durationSecs);
    return TransformedMedia(
      proxyUrl: hlsUrl,
      effectiveType: CastMediaType.hls,
    );
  }
}

@immutable
class GoogleCastState {
  const GoogleCastState({
    this.devices = const <CastDevice>[],
    this.discovering = false,
    this.connecting = false,
    this.connected = false,
    this.casting = false,
    this.isPlaying = false,
    this.deviceName,
    this.sessionState,
    this.position = Duration.zero,
    this.duration,
    this.error,
    this.lastDeviceName,
  });

  final List<CastDevice> devices;
  final bool discovering;
  final bool connecting;
  final bool connected;
  final bool casting;
  final bool isPlaying;
  final String? deviceName;
  final SessionState? sessionState;
  final Duration position;
  final Duration? duration;
  final String? error;
  final String? lastDeviceName;

  GoogleCastState copyWith({
    List<CastDevice>? devices,
    bool? discovering,
    bool? connecting,
    bool? connected,
    bool? casting,
    bool? isPlaying,
    String? deviceName,
    SessionState? sessionState,
    Duration? position,
    Duration? duration,
    String? error,
    String? lastDeviceName,
    bool clearError = false,
  }) {
    return GoogleCastState(
      devices: devices ?? this.devices,
      discovering: discovering ?? this.discovering,
      connecting: connecting ?? this.connecting,
      connected: connected ?? this.connected,
      casting: casting ?? this.casting,
      isPlaying: isPlaying ?? this.isPlaying,
      deviceName: deviceName ?? this.deviceName,
      sessionState: sessionState ?? this.sessionState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      lastDeviceName: lastDeviceName ?? this.lastDeviceName,
    );
  }
}

class GoogleCastController extends StateNotifier<GoogleCastState> {
  GoogleCastController(this._ref) : super(const GoogleCastState()) {
    _service = CastService(
      discoveryProviders: [ChromecastDiscoveryProvider()],
      sessionFactory: _createSession,
    );
    _restoreLastDeviceName();
  }

  final Ref _ref;
  late final CastService _service;

  CastSession? _session;
  StreamSubscription<List<CastDevice>>? _discoverySub;
  StreamSubscription<SessionState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  final List<MediaItem> _queue = [];
  int _queueIndex = 0;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  bool _casting = false;
  Timer? _idleTimer;
  int _discoveryGeneration = 0;
  Duration? _pendingStartPosition;

  static const Duration _discoveryTimeout = Duration(seconds: 8);

  CastSession _createSession(CastDevice device) {
    return ChromecastSession(
      device: device,
      mediaTransformer: const HarmonixCastMediaTransformer(),
    );
  }

  void _restoreLastDeviceName() {
    final settings = _ref.read(settingsRepositoryProvider);
    final raw = settings.castLastDevice;
    if (raw == null || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        final device = CastDevice.fromJson(json);
        state = state.copyWith(lastDeviceName: device.name);
      }
    } catch (_) {
      // Ignore corrupted stored device.
    }
  }

  // ---------------------------------------------------------------- Discovery

  Future<void> startDiscovery() async {
    if (state.discovering) return;
    final generation = ++_discoveryGeneration;
    state = state.copyWith(
      discovering: true,
      error: null,
      devices: const <CastDevice>[],
    );

    try {
      final stream = _service.startDiscovery(
        protocols: {CastProtocol.chromecast},
        timeout: _discoveryTimeout,
      );
      _discoverySub = stream.listen(
        (devices) {
          if (generation != _discoveryGeneration) return;
          state = state.copyWith(devices: devices);
        },
        onError: (Object e) {
          if (generation != _discoveryGeneration) return;
          state = state.copyWith(
            discovering: false,
            error: 'Erreur de découverte: $e',
          );
        },
        onDone: () {
          if (generation != _discoveryGeneration) return;
          state = state.copyWith(discovering: false);
        },
      );
    } catch (e) {
      state = state.copyWith(discovering: false, error: 'Erreur: $e');
    }
  }

  void stopDiscovery() {
    _discoveryGeneration++;
    _discoverySub?.cancel();
    _discoverySub = null;
    _service.stopDiscovery();
    if (state.discovering) {
      state = state.copyWith(discovering: false);
    }
  }

  // ------------------------------------------------------------------ Connect

  Future<void> connect(CastDevice device) async {
    if (state.connecting) return;
    state = state.copyWith(connecting: true, error: null);
    try {
      final session = await _service.connect(device);
      _session = session;

      await _stateSub?.cancel();
      await _positionSub?.cancel();
      await _durationSub?.cancel();
      _stateSub = session.stateStream.listen(_onSessionState);
      _positionSub = session.positionStream.listen((position) {
        state = state.copyWith(position: position);
      });
      _durationSub = session.durationStream.listen((duration) {
        state = state.copyWith(duration: duration);
      });

      state = state.copyWith(
        connecting: false,
        connected: true,
        casting: false,
        deviceName: device.name,
        sessionState: session.state,
        error: null,
      );
      _persistLastDevice(device);

      final handler = _ref.read(audioHandlerProvider);
      final current = handler.mediaItem.value;
      if (current != null) {
        await castCurrent();
      }
    } catch (e) {
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: 'Connexion impossible à ${device.name}: $e',
      );
    }
  }

  Future<bool> reconnectLastDevice() async {
    final settings = _ref.read(settingsRepositoryProvider);
    final raw = settings.castLastDevice;
    if (raw == null || raw.isEmpty) return false;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        await connect(CastDevice.fromJson(json));
        return state.connected;
      }
    } catch (_) {
      // Ignore corrupted stored device.
    }
    return false;
  }

  Future<void> disconnect() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    _casting = false;
    stopDiscovery();

    await _stateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _stateSub = null;
    _positionSub = null;
    _durationSub = null;

    final session = _session;
    _session = null;
    if (session != null) {
      try {
        await session.disconnect();
      } catch (_) {
        // Ignore disconnect errors.
      }
    }

    _queue.clear();
    _queueIndex = 0;
    state = const GoogleCastState();
    _restoreLastDeviceName();
  }

  // ------------------------------------------------------------------ Casting

  Future<void> castCurrent() async {
    final session = _session;
    if (session == null) return;

    final handler = _ref.read(audioHandlerProvider);
    final current = handler.mediaItem.value;
    final playbackState = handler.playbackState.value;
    final queue = handler.queue.value;

    if (current == null) return;

    _queue
      ..clear()
      ..addAll(queue);
    final index = queue.indexWhere((item) => item.id == current.id);
    _queueIndex = index < 0 ? 0 : index;
    _repeatMode = playbackState.repeatMode;
    _pendingStartPosition =
        state.position > Duration.zero ? state.position : null;

    await handler.pause();

    await _loadQueueItem(_queueIndex);
  }

  Future<void> _loadQueueItem(int index) async {
    final session = _session;
    if (session == null || _queue.isEmpty) return;
    if (index < 0 || index >= _queue.length) return;

    _queueIndex = index;
    _casting = true;
    _idleTimer?.cancel();
    _idleTimer = null;

    final item = _queue[index];
    final settings = _ref.read(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = settings.authToken;
    final headers =
        token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null;

    final url = streamUrl(baseUrl, item.id);
    final type = await _detectMediaType(url, headers);

    final startPosition = _pendingStartPosition;
    final media = CastMedia(
      url: url,
      type: type,
      httpHeaders: headers ?? const {},
      title: item.title,
      imageUrl: _artUrlForItem(baseUrl, item),
      duration: item.duration,
      startPosition: startPosition,
    );
    _pendingStartPosition = null;

    state = state.copyWith(
      casting: true,
      isPlaying: false,
      sessionState: SessionState.loading,
      error: null,
    );

    try {
      await session.loadMedia(media);
    } catch (e) {
      _casting = false;
      state = state.copyWith(
        casting: false,
        error: 'Échec de lecture sur ${state.deviceName}: $e',
      );
    }
  }

  Future<CastMediaType> _detectMediaType(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final contentType =
          (response.headers.value('content-type') ?? '').toLowerCase();
      final data = response.data;
      if (data is Stream<List<int>>) {
        try {
          await data.first.then((_) {}).timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        } catch (_) {
          // Ignore probe stream errors; headers were already received.
        }
      }
      if (contentType.contains('mpegurl') ||
          url.toLowerCase().contains('.m3u8')) {
        return CastMediaType.hls;
      }
    } catch (_) {
      // Probe failed — assume a plain audio file wrapped in HLS.
    }
    return CastMediaType.mp4;
  }

  String? _artUrlForItem(String baseUrl, MediaItem item) {
    final coverFile = item.extras?['coverFile'] as String?;
    if (coverFile != null && coverFile.isNotEmpty) {
      return coverUrl(baseUrl, coverFile);
    }
    return item.artUri?.toString();
  }

  // ------------------------------------------------------------ Playback cmds

  Future<void> play() async {
    try {
      await _session?.play();
    } catch (_) {
      // Ignore — media may not be loaded yet.
    }
  }

  Future<void> pause() async {
    try {
      await _session?.pause();
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _session?.seek(position);
      state = state.copyWith(position: position);
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> skipToNext() => _advance(1);

  Future<void> skipToPrevious() => _advance(-1);

  Future<void> _advance(int delta) async {
    final session = _session;
    if (session == null || !_casting || _queue.isEmpty) return;

    _pendingStartPosition = null;
    var next = _queueIndex + delta;
    if (next < 0 || next >= _queue.length) {
      if (_repeatMode != AudioServiceRepeatMode.all) return;
      next = (next + _queue.length) % _queue.length;
    }
    await _loadQueueItem(next);
  }

  void _onSessionState(SessionState sessionState) {
    if (_session == null) return;
    final isPlaying = sessionState == SessionState.playing ||
        sessionState == SessionState.buffering;
    state = state.copyWith(
      sessionState: sessionState,
      isPlaying: isPlaying,
    );

    if (sessionState == SessionState.idle) {
      _scheduleAutoAdvance();
    }
  }

  void _scheduleAutoAdvance() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 900), () {
      _idleTimer = null;
      if (!_casting || _session == null) return;
      _advance(1);
    });
  }

  /// Returns to local playback while staying connected to the cast device.
  Future<void> stopCasting() async {
    final session = _session;
    if (session == null) return;

    _idleTimer?.cancel();
    _idleTimer = null;
    _casting = false;

    final castPosition = state.position;
    try {
      await session.stop();
    } catch (_) {
      // Ignore.
    }

    final handler = _ref.read(audioHandlerProvider);
    if (handler.mediaItem.value != null) {
      if (castPosition > Duration.zero) {
        await handler.seek(castPosition);
      }
      await handler.play();
    }

    state = state.copyWith(
      casting: false,
      isPlaying: true,
      sessionState: SessionState.connected,
    );
  }

  void _persistLastDevice(CastDevice device) {
    try {
      _ref
          .read(settingsRepositoryProvider)
          .setCastLastDevice(jsonEncode(device.toJson()));
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _discoverySub?.cancel();
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }
}

final googleCastProvider =
    StateNotifierProvider<GoogleCastController, GoogleCastState>((ref) {
  return GoogleCastController(ref);
});
