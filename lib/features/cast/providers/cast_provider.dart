import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/features/cast/data/cast_repository.dart';

class CastState {
  const CastState({
    this.sessionId,
    this.connecting = false,
    this.error,
  });

  final String? sessionId;
  final bool connecting;
  final String? error;

  bool get isActive => sessionId != null && sessionId!.isNotEmpty;

  CastState copyWith({
    String? sessionId,
    bool? connecting,
    String? error,
    bool clearError = false,
  }) {
    return CastState(
      sessionId: sessionId ?? this.sessionId,
      connecting: connecting ?? this.connecting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CastController extends StateNotifier<CastState> {
  CastController(this._ref) : super(const CastState());

  final Ref _ref;

  Future<void> start() async {
    final handler = _ref.read(audioHandlerProvider);
    final item = handler.mediaItem.value;
    final playback = handler.playbackState.value;
    if (item == null) {
      state = state.copyWith(error: 'Aucune piste en cours');
      return;
    }

    state = state.copyWith(connecting: true, clearError: true);
    try {
      final sessionId = await _ref.read(castRepositoryProvider).createSession(
            trackId: item.id,
            positionMs: playback.updatePosition.inMilliseconds,
            isPlaying: playback.playing,
          );
      state = state.copyWith(
        sessionId: sessionId,
        connecting: false,
      );
    } catch (e) {
      state = state.copyWith(
        connecting: false,
        error: 'Impossible de créer la session Cast',
      );
    }
  }

  Future<void> syncPlaybackState() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    final handler = _ref.read(audioHandlerProvider);
    final item = handler.mediaItem.value;
    final playback = handler.playbackState.value;
    try {
      await _ref.read(castRepositoryProvider).updateSession(
            sessionId,
            trackId: item?.id,
            positionMs: playback.updatePosition.inMilliseconds,
            isPlaying: playback.playing,
          );
    } catch (_) {
      state = state.copyWith(error: 'Synchronisation Cast échouée');
    }
  }

  Future<void> end() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      await _ref.read(castRepositoryProvider).endSession(sessionId);
    } finally {
      state = const CastState();
    }
  }
}

final castProvider = StateNotifierProvider<CastController, CastState>((ref) {
  return CastController(ref);
});

final castPlaybackSyncProvider = Provider<void>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  final sub = handler.playbackState.listen((PlaybackState _) {
    final cast = ref.read(castProvider);
    if (cast.isActive) {
      ref.read(castProvider.notifier).syncPlaybackState();
    }
  });
  ref.onDispose(sub.cancel);
});
