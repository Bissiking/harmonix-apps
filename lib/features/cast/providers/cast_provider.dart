import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/cast/data/cast_repository.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';

class CastState {
  const CastState({
    this.sessionId,
    this.sessionCode,
    this.role,
    this.connecting = false,
    this.error,
    this.stateVersion = 0,
    this.lastSession,
  });

  final String? sessionId;
  final String? sessionCode;
  final String? role;
  final bool connecting;
  final String? error;
  final int stateVersion;
  final Map<String, dynamic>? lastSession;

  bool get isActive => sessionId != null && sessionId!.isNotEmpty;

  CastState copyWith({
    String? sessionId,
    String? sessionCode,
    String? role,
    bool? connecting,
    String? error,
    int? stateVersion,
    Map<String, dynamic>? lastSession,
    bool clearError = false,
  }) {
    return CastState(
      sessionId: sessionId ?? this.sessionId,
      sessionCode: sessionCode ?? this.sessionCode,
      role: role ?? this.role,
      connecting: connecting ?? this.connecting,
      error: clearError ? null : (error ?? this.error),
      stateVersion: stateVersion ?? this.stateVersion,
      lastSession: lastSession ?? this.lastSession,
    );
  }
}

class CastController extends StateNotifier<CastState> {
  CastController(this._ref) : super(const CastState()) {
    _restorePersistedSession();
  }

  final Ref _ref;
  Timer? _syncDebounce;
  Timer? _pollTimer;
  DateTime _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _ignoreSyncUntil = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> start({String role = 'host'}) async {
    final handler = _ref.read(audioHandlerProvider);
    final playback = handler.playbackState.value;
    final now = handler.mediaItem.value;
    final queue = handler.queue.value;
    final sessionState = _buildRiftState(
      nowPlaying: now,
      queue: queue,
      playback: playback,
      role: role,
      lastCommand: 'create',
    );

    state = state.copyWith(connecting: true, clearError: true);
    try {
      final sessionId = await _ref.read(castRepositoryProvider).createSession(
            deviceId: _deviceId(_ref),
            stateVersion: state.stateVersion + 1,
            state: sessionState,
          );
      final session = sessionId == null
          ? null
          : await _ref.read(castRepositoryProvider).getSession(sessionId);
      state = state.copyWith(
        sessionId: sessionId,
        sessionCode: _readSessionCode(session),
        role: role,
        lastSession: session,
        connecting: false,
        stateVersion: state.stateVersion + 1,
      );
      await _ref.read(settingsRepositoryProvider).setRiftSessionId(sessionId);
      _startPolling();
    } catch (_) {
      state = state.copyWith(
        connecting: false,
        error: 'Impossible de créer la session RIFT',
      );
    }
  }

  Future<void> join({
    required String sessionId,
    String? code,
    String role = 'listen',
  }) async {
    state = state.copyWith(connecting: true, clearError: true);
    try {
      await _ref.read(castRepositoryProvider).joinSession(
            sessionId,
            deviceId: _deviceId(_ref),
            code: code,
            role: role,
          );
      final session = await _ref.read(castRepositoryProvider).getSession(sessionId);
      state = state.copyWith(
        connecting: false,
        sessionId: sessionId,
        sessionCode: _readSessionCode(session) ?? code,
        role: role,
        lastSession: session,
      );
      await _ref.read(settingsRepositoryProvider).setRiftSessionId(sessionId);
      _startPolling();
    } catch (_) {
      state = state.copyWith(
        connecting: false,
        error: 'Impossible de rejoindre la session RIFT',
      );
    }
  }

  Future<void> syncPlaybackState() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    if (DateTime.now().isBefore(_ignoreSyncUntil)) return;
    final nowTs = DateTime.now();
    if (nowTs.difference(_lastSyncAt).inMilliseconds < 500) {
      _syncDebounce?.cancel();
      _syncDebounce = Timer(const Duration(milliseconds: 550), () {
        syncPlaybackState();
      });
      return;
    }
    _lastSyncAt = nowTs;

    final handler = _ref.read(audioHandlerProvider);
    final playback = handler.playbackState.value;
    final now = handler.mediaItem.value;
    final queue = handler.queue.value;
    final nextVersion = state.stateVersion + 1;
    try {
      await _ref.read(castRepositoryProvider).updateSession(
            sessionId,
            deviceId: _deviceId(_ref),
            stateVersion: nextVersion,
            state: _buildRiftState(
              nowPlaying: now,
              queue: queue,
              playback: playback,
              role: state.role,
              lastCommand: 'playback_state',
            ),
          );
      state = state.copyWith(stateVersion: nextVersion, clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Synchronisation RIFT échouée');
    }
  }

  Future<void> poll() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      final session = await _ref.read(castRepositoryProvider).getSession(sessionId);
      await _applyRemoteState(session);
      state = state.copyWith(
        lastSession: session,
        sessionCode: _readSessionCode(session) ?? state.sessionCode,
        role: _readMyRole(session) ?? state.role,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(error: 'Lecture de session RIFT échouée');
    }
  }

  Future<void> setParticipantMode(String mode) async {
    await _sendAction('participant_mode', payload: {'mode': mode});
    state = state.copyWith(role: mode);
  }

  Future<void> leave() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      await _sendAction('leave');
    } finally {
      _stopPolling();
      await _ref.read(settingsRepositoryProvider).setRiftSessionId(null);
      state = const CastState();
    }
  }

  Future<void> queueAdd(String trackId) =>
      _sendAction('queue_add', payload: {'track_id': trackId});

  Future<void> queueRemove(String trackId) =>
      _sendAction('queue_remove', payload: {'track_id': trackId});

  Future<void> queueClear() => _sendAction('queue_clear');

  Future<void> queuePlay(String trackId) =>
      _sendAction('queue_play', payload: {'track_id': trackId});

  Future<void> playbackState({
    required bool isPlaying,
    int? positionSeconds,
    String? trackId,
  }) => _sendAction(
        'playback_state',
        payload: {
          'is_playing': isPlaying,
          if (positionSeconds != null) 'position_seconds': positionSeconds,
          if (trackId != null && trackId.isNotEmpty) 'track_id': trackId,
        },
      );

  Future<void> sendCommand(String command, {Map<String, dynamic>? payload}) =>
      _sendAction(
        'command',
        payload: {
          'command': command,
          if (payload != null) ...payload,
        },
      );

  Future<void> end() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      await _ref.read(castRepositoryProvider).endSession(sessionId);
    } finally {
      _stopPolling();
      await _ref.read(settingsRepositoryProvider).setRiftSessionId(null);
      state = const CastState();
    }
  }

  Future<void> _sendAction(String action, {Map<String, dynamic>? payload}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      await _ref.read(castRepositoryProvider).sendStateAction(
            sessionId,
            deviceId: _deviceId(_ref),
            action: action,
            payload: payload,
          );
      state = state.copyWith(clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Action RIFT "$action" échouée');
    }
  }

  Future<void> _restorePersistedSession() async {
    final settings = _ref.read(settingsRepositoryProvider);
    final persistedSessionId = settings.riftSessionId;
    if (persistedSessionId == null || persistedSessionId.isEmpty) return;
    state = state.copyWith(sessionId: persistedSessionId);
    _startPolling();
    await poll();
    await syncPlaybackState();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!state.isActive) return;
      poll();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _applyRemoteState(Map<String, dynamic>? session) async {
    if (session == null) return;
    final myRole = _readMyRole(session) ?? state.role;
    if (myRole == 'host') return;

    final rootPlayback = session['playback'];
    final statePlayback = (session['state'] as Map?)?['playback'];
    final playbackMap = switch (rootPlayback) {
      Map<String, dynamic>() => rootPlayback,
      Map() => rootPlayback.cast<String, dynamic>(),
      _ => switch (statePlayback) {
          Map<String, dynamic>() => statePlayback,
          Map() => statePlayback.cast<String, dynamic>(),
          _ => <String, dynamic>{},
        },
    };

    final queueRaw = session['queue'] ?? (session['state'] as Map?)?['queue'];
    final queueIds = <String>[
      if (queueRaw is List)
        ...queueRaw.whereType<String>().where((id) => id.trim().isNotEmpty),
    ];

    final remoteTrackId = playbackMap['track_id'];
    final remoteIsPlaying = playbackMap['is_playing'];
    final remotePos = playbackMap['position_seconds'];
    final remoteRepeat = playbackMap['repeat'];
    final remoteShuffle = playbackMap['shuffle'];

    final player = _ref.read(playerProvider.notifier);
    final handler = _ref.read(audioHandlerProvider);

    if (queueIds.isNotEmpty) {
      final tracks = <dynamic>[];
      for (final id in queueIds) {
        try {
          final track = await _ref.read(catalogRepositoryProvider).getTrack(id);
          tracks.add(track);
        } catch (_) {}
      }
      if (tracks.isNotEmpty) {
        final idx = remoteTrackId is String ? queueIds.indexOf(remoteTrackId) : -1;
        if (idx >= 0 && idx < tracks.length) {
          _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
          await player.playFromQueue(List.from(tracks), idx);
        }
      }
    } else if (remoteTrackId is String && remoteTrackId.isNotEmpty) {
      final currentTrackId = handler.mediaItem.value?.id;
      if (currentTrackId != remoteTrackId) {
        try {
          final track = await _ref.read(catalogRepositoryProvider).getTrack(remoteTrackId);
          _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
          await player.playTrack(track);
        } catch (_) {}
      }
    }

    if (remotePos is num) {
      _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
      await player.seek(Duration(seconds: remotePos.toInt()));
    }
    if (remoteRepeat is String) {
      _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
      await player.setRepeat(_repeatFromString(remoteRepeat));
    }
    if (remoteShuffle is bool) {
      _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
      await player.setShuffle(remoteShuffle);
    }
    if (remoteIsPlaying is bool) {
      _ignoreSyncUntil = DateTime.now().add(const Duration(seconds: 2));
      if (remoteIsPlaying) {
        await player.play();
      } else {
        await player.pause();
      }
    }
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _stopPolling();
    super.dispose();
  }
}

final riftProvider = StateNotifierProvider<CastController, CastState>((ref) {
  return CastController(ref);
});

final riftPlaybackSyncProvider = Provider<void>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final sub = handler.playbackState.listen((PlaybackState _) {
    final cast = ref.read(riftProvider);
    if (cast.isActive) {
      ref.read(riftProvider.notifier).syncPlaybackState();
    }
  });
  ref.onDispose(sub.cancel);
});

// Backward compatibility during migration.
final castProvider = riftProvider;
final castPlaybackSyncProvider = riftPlaybackSyncProvider;

String _deviceId(Ref ref) =>
    ref.read(settingsRepositoryProvider).getOrCreateRiftDeviceId();

Map<String, dynamic> _buildRiftState({
  required MediaItem? nowPlaying,
  required List<MediaItem> queue,
  required PlaybackState playback,
  String? role,
  String? lastCommand,
}) {
  return <String, dynamic>{
    'session': {
      'host': role == 'host',
    },
    'playback': {
      'track_id': nowPlaying?.id,
      'position_seconds': playback.updatePosition.inMilliseconds ~/ 1000,
      'is_playing': playback.playing,
      'repeat': playback.repeatMode.name,
      'shuffle': playback.shuffleMode.name != 'none',
    },
    'queue': queue.map((item) => item.id).toList(),
    if (lastCommand != null) 'last_command': lastCommand,
  };
}

String? _readSessionCode(Map<String, dynamic>? session) {
  final code = session?['code'] ?? (session?['session'] as Map?)?['code'];
  return code is String && code.isNotEmpty ? code : null;
}

String? _readMyRole(Map<String, dynamic>? session) {
  final participants = session?['participants'];
  if (participants is List && participants.isNotEmpty) {
    final me = participants.firstWhere(
      (p) => p is Map && p['is_self'] == true,
      orElse: () => null,
    );
    if (me is Map) {
      final role = me['mode'] ?? me['role'];
      if (role is String && role.isNotEmpty) return role;
    }
  }
  final role = session?['role'];
  if (role is String && role.isNotEmpty) return role;
  return null;
}

AudioServiceRepeatMode _repeatFromString(String repeat) {
  switch (repeat) {
    case 'one':
      return AudioServiceRepeatMode.one;
    case 'group':
    case 'all':
      return AudioServiceRepeatMode.all;
    case 'none':
    default:
      return AudioServiceRepeatMode.none;
  }
}
