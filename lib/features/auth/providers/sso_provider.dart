import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/features/auth/data/sso_repository.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';

enum SsoPhase { idle, connecting, waiting, error, done }

class SsoState {
  const SsoState({
    this.phase = SsoPhase.idle,
    this.error,
  });

  final SsoPhase phase;
  final String? error;

  bool get busy => phase == SsoPhase.connecting || phase == SsoPhase.waiting;

  SsoState copyWith({SsoPhase? phase, String? error, bool clearError = false}) {
    return SsoState(
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SsoController extends StateNotifier<SsoState> {
  SsoController(this._ref) : super(const SsoState());

  final Ref _ref;
  Timer? _pollTimer;
  String? _activeState;
  int _pollAttempts = 0;

  static const _maxPollAttempts = 60;
  static const _pollInterval = Duration(seconds: 2);

  /// Démarre le flow SSO : ouvre le navigateur vers le relais web puis
  /// interroge celui-ci jusqu'à récupérer le token.
  Future<void> start() async {
    if (state.busy) return;
    final stateId = _generateState();
    _activeState = stateId;
    _pollAttempts = 0;
    state = state.copyWith(phase: SsoPhase.connecting, clearError: true);

    try {
      final repo = _ref.read(ssoRepositoryProvider);
      final url = await repo.start(stateId, platform: _platformName());
      if (url == null || url.isEmpty) {
        throw StateError('SSO indisponible sur ce serveur');
      }
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw StateError('URL SSO invalide');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      state = state.copyWith(phase: SsoPhase.waiting);
      _startPolling();
    } catch (_) {
      state = state.copyWith(
        phase: SsoPhase.error,
        error: 'Impossible de démarrer le SSO.',
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final stateId = _activeState;
    if (stateId == null) return;
    _pollAttempts++;
    if (_pollAttempts > _maxPollAttempts) {
      _stopPolling();
      state = state.copyWith(
        phase: SsoPhase.error,
        error: 'SSO expiré, réessaie.',
      );
      return;
    }
    try {
      final tokens = await _ref.read(ssoRepositoryProvider).getTokens(stateId);
      if (tokens == null) return; // pas encore prêt
      _stopPolling();
      _activeState = null;
      await _ref.read(settingsRepositoryProvider).setAuthSession(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresInSeconds: tokens.expiresInSeconds,
          );
      _ref.invalidate(dioProvider);
      _ref.invalidate(authTokenProvider);
      _ref.invalidate(bootstrapProvider);
      _ref.read(requireLoginProvider.notifier).state = false;
      state = state.copyWith(phase: SsoPhase.done, clearError: true);
    } catch (_) {
      // 404 tant que le relais n'a pas terminé : on continue de sonder.
    }
  }

  void reset() {
    _stopPolling();
    _activeState = null;
    state = const SsoState();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'android',
    };
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

final ssoProvider = StateNotifierProvider<SsoController, SsoState>((ref) {
  return SsoController(ref);
});
