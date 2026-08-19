import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/session/auth_session_tokens.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

enum AuthRefreshResult { refreshed, stillValid, unavailable, invalid }

class AuthRefreshService {
  AuthRefreshService({
    required SettingsRepository settings,
    required void Function() onSessionChanged,
    Dio? client,
  })  : _settings = settings,
        _onSessionChanged = onSessionChanged,
        _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final SettingsRepository _settings;
  final void Function() _onSessionChanged;
  final Dio _client;
  Future<AuthRefreshResult>? _inFlight;

  Future<AuthRefreshResult> refresh({bool force = false}) {
    final active = _inFlight;
    if (active != null) return active;
    final operation = _performRefresh(force: force);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<AuthRefreshResult> _performRefresh({required bool force}) async {
    final refreshToken = _settings.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return AuthRefreshResult.invalid;
    }
    final expiresAt = _settings.tokenExpiresAt;
    if (!force &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 45)))) {
      return AuthRefreshResult.stillValid;
    }

    try {
      final baseUrl = _normalizedBaseUrl(_settings.serverUrl);
      final response = await _client.post<dynamic>(
        '$baseUrl/api/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(contentType: Headers.jsonContentType),
      );
      final tokens = AuthSessionTokens.fromJson(response.data);
      if (tokens == null) return AuthRefreshResult.invalid;
      await _settings.setAuthSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken ?? refreshToken,
        expiresInSeconds: tokens.expiresInSeconds,
      );
      _onSessionChanged();
      return AuthRefreshResult.refreshed;
    } on DioException catch (error) {
      final status = error.response?.statusCode ?? 0;
      if (status == 400 || status == 401) {
        return AuthRefreshResult.invalid;
      }
      return AuthRefreshResult.unavailable;
    } catch (_) {
      return AuthRefreshResult.unavailable;
    }
  }

  Future<void> expireSession() async {
    await _settings.clearAuthSession();
    _onSessionChanged();
  }
}

final authRefreshServiceProvider = Provider<AuthRefreshService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return AuthRefreshService(
    settings: settings,
    onSessionChanged: () => ref.invalidate(authTokenProvider),
  );
});

final sessionKeepAliveProvider = Provider<void>((ref) {
  final token = ref.watch(authTokenProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final refreshToken = settings.refreshToken;
  final expiresAt = settings.tokenExpiresAt;
  if (token == null ||
      token.isEmpty ||
      refreshToken == null ||
      refreshToken.isEmpty ||
      expiresAt == null) {
    return;
  }

  final refreshAt = expiresAt.subtract(const Duration(seconds: 45));
  final delay = refreshAt.difference(DateTime.now());
  Timer? timer;
  var disposed = false;

  late void Function(Duration delay) schedule;
  schedule = (nextDelay) {
    timer = Timer(nextDelay, () async {
      final result =
          await ref.read(authRefreshServiceProvider).refresh(force: true);
      if (disposed) return;
      if (result == AuthRefreshResult.invalid) {
        await ref.read(authRefreshServiceProvider).expireSession();
        ref.read(requireLoginProvider.notifier).state = true;
      } else if (result == AuthRefreshResult.unavailable) {
        schedule(const Duration(seconds: 30));
      }
    });
  };

  schedule(delay.isNegative ? Duration.zero : delay);
  ref.onDispose(() {
    disposed = true;
    timer?.cancel();
  });
});

String _normalizedBaseUrl(String rawUrl) {
  final trimmed = rawUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}
