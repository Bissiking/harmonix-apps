import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/session/auth_session_tokens.dart';
import 'package:harmonix_apps/features/auth/data/device_authorization_repository.dart';

enum DeviceLoginPhase {
  idle,
  requesting,
  waiting,
  unavailable,
  denied,
  expired,
  saving,
  done
}

class DeviceLoginState {
  const DeviceLoginState(
      {this.phase = DeviceLoginPhase.idle,
      this.userCode,
      this.verificationUri,
      this.qrUri,
      this.expiresAt});
  final DeviceLoginPhase phase;
  final String? userCode;
  final Uri? verificationUri;
  final Uri? qrUri;
  final DateTime? expiresAt;
  bool get busy => [
        DeviceLoginPhase.requesting,
        DeviceLoginPhase.waiting,
        DeviceLoginPhase.saving
      ].contains(phase);
}

/// One outstanding poll, one-shot scheduling and a generation fence: a stale
/// request can never save a session after cancellation or a new attempt.
class DeviceLoginController extends StateNotifier<DeviceLoginState> {
  DeviceLoginController(this.repository, this.saveSession,
      {DateTime Function()? now})
      : now = now ?? DateTime.now,
        super(const DeviceLoginState());
  final DeviceAuthorizationRepository repository;
  final Future<void> Function(AuthSessionTokens) saveSession;
  final DateTime Function() now;
  Timer? _timer;
  int _generation = 0;
  Duration _interval = const Duration(seconds: 5);
  DeviceAuthorization? _grant;
  DeviceLoginConfiguration? _configuration;
  DateTime? _expiresAt;

  Future<void> start() async {
    if (state.busy) return;
    final generation = ++_generation;
    _clear();
    state = const DeviceLoginState(phase: DeviceLoginPhase.requesting);
    try {
      final configuration = await repository.configuration();
      if (!_active(generation)) return;
      final grant = await repository.authorize(configuration);
      if (!_active(generation)) return;
      _configuration = configuration;
      _grant = grant;
      _expiresAt = now().add(grant.expiresIn);
      _interval = grant.interval;
      state = DeviceLoginState(
          phase: DeviceLoginPhase.waiting,
          userCode: grant.userCode,
          verificationUri: grant.verificationUri,
          qrUri: grant.verificationUriComplete,
          expiresAt: _expiresAt);
      _schedule(generation);
    } catch (_) {
      if (_active(generation)) _finish(DeviceLoginPhase.unavailable);
    }
  }

  bool _active(int generation) => mounted && generation == _generation;

  void _schedule(int generation, [Duration? delay]) {
    if (!_active(generation)) return;
    final remaining = _expiresAt!.difference(now());
    if (remaining <= Duration.zero) {
      _finish(DeviceLoginPhase.expired);
      return;
    }
    final next = delay ?? _interval;
    _timer =
        Timer(next < remaining ? next : remaining, () => _poll(generation));
  }

  Future<void> _poll(int generation) async {
    if (!_active(generation)) return;
    if (!now().isBefore(_expiresAt!)) {
      _finish(DeviceLoginPhase.expired);
      return;
    }
    try {
      final tokens = await repository.poll(_configuration!, _grant!.deviceCode);
      if (!_active(generation)) return;
      _clear();
      state = const DeviceLoginState(phase: DeviceLoginPhase.saving);
      await saveSession(tokens);
      if (_active(generation)) {
        state = const DeviceLoginState(phase: DeviceLoginPhase.done);
      }
    } on DeviceLoginFailure catch (error) {
      if (!_active(generation)) return;
      switch (error.code) {
        case 'authorization_pending':
          _schedule(generation);
        case 'slow_down':
          _interval += const Duration(seconds: 5);
          _schedule(generation, _longest(_interval, error.retryAfter));
        case 'temporarily_unavailable':
          _interval = _longest(_interval * 2, error.retryAfter);
          _schedule(generation);
        case 'access_denied':
          _finish(DeviceLoginPhase.denied);
        case 'expired_token':
          _finish(DeviceLoginPhase.expired);
        default:
          _finish(DeviceLoginPhase.unavailable);
      }
    } on FormatException {
      if (_active(generation)) _finish(DeviceLoginPhase.unavailable);
    } catch (_) {
      if (!_active(generation)) return;
      if (state.phase == DeviceLoginPhase.saving) {
        _finish(DeviceLoginPhase.unavailable);
      } else {
        _interval *= 2;
        _schedule(generation);
      }
    }
  }

  Duration _longest(Duration value, Duration? other) =>
      other != null && other > value ? other : value;

  void _finish(DeviceLoginPhase phase) {
    _clear();
    state = DeviceLoginState(phase: phase);
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _grant = null;
    _configuration = null;
    _expiresAt = null;
  }

  void reset() {
    // A consumed grant is being persisted; do not start a concurrent login.
    if (state.phase == DeviceLoginPhase.saving) return;
    _generation++;
    _clear();
    state = const DeviceLoginState();
  }

  @override
  void dispose() {
    _generation++;
    _clear();
    super.dispose();
  }
}
