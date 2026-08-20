import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

const _keyServerUrl = 'server_url';
const _keyAuthToken = 'auth_token';
const _keyRefreshToken = 'refresh_token';
const _keyTokenExpiresAt = 'token_expires_at';
const _keyThemeJson = 'theme_json';
const _keyThemeMode = 'theme_mode';
const _keyRiftSessionId = 'rift_session_id';
const _keyRiftDeviceId = 'rift_device_id';
const _keyCastLastDevice = 'cast_last_device';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? _defaultServerUrl;

  Future<void> setServerUrl(String url) => _prefs.setString(_keyServerUrl, url);

  String? get authToken => _prefs.getString(_keyAuthToken) ?? _defaultAuthToken;

  String? get refreshToken => _prefs.getString(_keyRefreshToken);

  DateTime? get tokenExpiresAt {
    final milliseconds = _prefs.getInt(_keyTokenExpiresAt);
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await clearAuthSession();
      return;
    }
    await _prefs.setString(_keyAuthToken, token);
  }

  Future<void> setAuthSession({
    required String accessToken,
    String? refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiresAt = DateTime.now().add(
      Duration(seconds: expiresInSeconds > 0 ? expiresInSeconds : 900),
    );
    await _prefs.setString(_keyAuthToken, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_keyRefreshToken, refreshToken);
    } else {
      await _prefs.remove(_keyRefreshToken);
    }
    await _prefs.setInt(
      _keyTokenExpiresAt,
      expiresAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyTokenExpiresAt);
  }

  String? get themeJson => _prefs.getString(_keyThemeJson);

  Future<void> setThemeJson(String json) =>
      _prefs.setString(_keyThemeJson, json);

  ThemeMode get themeMode {
    final raw = _prefs.getString(_keyThemeMode);
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_keyThemeMode, mode.name);

  String? get riftSessionId => _prefs.getString(_keyRiftSessionId);

  Future<void> setRiftSessionId(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      await _prefs.remove(_keyRiftSessionId);
      return;
    }
    await _prefs.setString(_keyRiftSessionId, sessionId);
  }

  String getOrCreateRiftDeviceId() {
    final existing = _prefs.getString(_keyRiftDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = 'device-${DateTime.now().millisecondsSinceEpoch}';
    _prefs.setString(_keyRiftDeviceId, created);
    return created;
  }

  String? get castLastDevice => _prefs.getString(_keyCastLastDevice);

  Future<void> setCastLastDevice(String? json) async {
    if (json == null || json.isEmpty) {
      await _prefs.remove(_keyCastLastDevice);
      return;
    }
    await _prefs.setString(_keyCastLastDevice, json);
  }

  static String get _defaultServerUrl => const String.fromEnvironment(
        'HARMONIX_API_BASE_URL',
        defaultValue: 'https://sonora.mhemery.fr',
      );

  static String? get _defaultAuthToken {
    const token = String.fromEnvironment('HARMONIX_API_TOKEN');
    return token.isEmpty ? null : token;
  }
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden after SharedPreferences.getInstance()',
  );
}
