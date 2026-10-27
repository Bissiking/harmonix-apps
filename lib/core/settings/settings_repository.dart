// settings_repository.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
const _keyShuffleEnabled = 'flow_shuffle';
const _keyRepeatMode = 'flow_repeat';
const _keyLibrarySort = 'library_sort';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  FlutterSecureStorage? _secure;
  String? _accessToken;
  String? _refreshToken;
  bool sessionStorageUnavailable = false;

  Future<void> initializeSecureSession(FlutterSecureStorage storage) async {
    try {
      await migrateSecureSession(storage);
      sessionStorageUnavailable = false;
    } catch (_) {
      // A locked/unavailable keychain must not block the local library. Keep
      // legacy data intact; new token writes still require the secure backend.
      _secure = storage;
      _accessToken = _prefs.getString(_keyAuthToken);
      _refreshToken = _prefs.getString(_keyRefreshToken);
      if (_accessToken != null) await _identifyAccount(_accessToken!);
      sessionStorageUnavailable = true;
    }
  }

  /// Copy first, verify, then remove legacy plaintext. Never erase on failure.
  Future<void> migrateSecureSession(FlutterSecureStorage storage) async {
    for (final key in [_keyAuthToken, _keyRefreshToken]) {
      final legacy = _prefs.getString(key);
      if (legacy != null && await storage.read(key: key) == null) {
        await storage.write(key: key, value: legacy);
        if (await storage.read(key: key) != legacy) {
          throw StateError('Session migration failed');
        }
      }
    }
    _accessToken = await storage.read(key: _keyAuthToken);
    _refreshToken = await storage.read(key: _keyRefreshToken);
    _secure = storage;
    if (_accessToken != null) await _identifyAccount(_accessToken!);
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyRefreshToken);
  }

  String get libraryScope => sha256
      .convert(utf8.encode(
          '${serverUrl.trim().replaceFirst(RegExp(r"/+$"), "")}::${_prefs.getString("local_account_id") ?? "guest"}'))
      .toString();

  String? get appearance => _prefs.getString('flow_appearance');
  bool get dynamicColors => _prefs.getBool('flow_dynamic_colors') ?? true;
  bool get reduceMotion => _prefs.getBool('flow_reduce_motion') ?? false;
  bool get offlineMode => _prefs.getBool('flow_offline') ?? false;
  bool get audioCacheEnabled =>
      _prefs.getBool('audio_cache_$libraryScope') ?? false;
  int get audioCacheLimitMb =>
      _prefs.getInt('audio_cache_limit_$libraryScope') ?? 256;
  Future<void> setAudioCacheEnabled(bool value) =>
      _prefs.setBool('audio_cache_$libraryScope', value);
  Future<void> setAudioCacheLimitMb(int value) async {
    if (![64, 128, 256, 512].contains(value)) {
      throw ArgumentError('Invalid cache size');
    }
    await _prefs.setInt('audio_cache_limit_$libraryScope', value);
  }

  bool get nightSenseEnabled =>
      _prefs.getBool('night_sense_$libraryScope') ?? false;

  /// Last "Aléatoire" state, restored at startup so the choice survives an
  /// app restart (and matches what Android Auto reports).
  bool get shuffleEnabled => _prefs.getBool(_keyShuffleEnabled) ?? false;
  Future<void> setShuffleEnabled(bool value) =>
      _prefs.setBool(_keyShuffleEnabled, value);

  /// Last "Boucle" state as an [AudioServiceRepeatMode] name:
  /// `none` | `one` | `all` | `group`.
  String get repeatMode => _prefs.getString(_keyRepeatMode) ?? 'none';
  Future<void> setRepeatMode(String value) =>
      _prefs.setString(_keyRepeatMode, value);

  /// Order used by the Morceaux tab. Defaults to "Ajout récent".
  String get librarySort => _prefs.getString(_keyLibrarySort) ?? 'recent';
  Future<void> setLibrarySort(String value) =>
      _prefs.setString(_keyLibrarySort, value);
  Future<void> setAppearance(String name) =>
      _prefs.setString('flow_appearance', name);
  Future<void> setDynamicColors(bool value) =>
      _prefs.setBool('flow_dynamic_colors', value);
  Future<void> setReduceMotion(bool value) =>
      _prefs.setBool('flow_reduce_motion', value);
  Future<void> setOfflineMode(bool value) =>
      _prefs.setBool('flow_offline', value);
  Future<void> setNightSenseEnabled(bool value) =>
      _prefs.setBool('night_sense_$libraryScope', value);

  Future<void> _writeToken(String key, String? token) async {
    if (_secure != null) {
      if (token == null) {
        await _secure!.delete(key: key);
      } else {
        await _secure!.write(key: key, value: token);
      }
      if (key == _keyAuthToken) _accessToken = token;
      if (key == _keyRefreshToken) _refreshToken = token;
    } else {
      if (token == null) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, token);
      }
    }
  }

  Future<void> _identifyAccount(String token, {bool newLogin = false}) async {
    String? subject;
    try {
      final claims = jsonDecode(utf8
          .decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
      subject = claims['sub']?.toString();
    } catch (_) {}
    if (subject != null ||
        newLogin ||
        _prefs.getString('local_account_id') == null) {
      await _prefs.setString('local_account_id',
          subject ?? sha256.convert(utf8.encode(token)).toString());
    }
  }

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? _defaultServerUrl;

  Future<void> setServerUrl(String url) async {
    final trimmed = url.trim();
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('URL Sonora invalide');
    }
    if (serverUrl.replaceFirst(RegExp(r'/+$'), '') !=
        normalized.replaceFirst(RegExp(r'/+$'), '')) {
      await clearAuthSession();
      await setRiftSessionId(null);
      await setOfflineMode(false);
    }
    await _prefs.setString(_keyServerUrl, normalized);
  }

  String? get authToken =>
      (_secure != null ? _accessToken : _prefs.getString(_keyAuthToken)) ??
      _defaultAuthToken;

  String? get refreshToken =>
      _secure != null ? _refreshToken : _prefs.getString(_keyRefreshToken);

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
    await _writeToken(_keyAuthToken, token);
    await _identifyAccount(token, newLogin: true);
  }

  Future<void> setAuthSession({
    required String accessToken,
    String? refreshToken,
    required int expiresInSeconds,
    bool newLogin = false,
  }) async {
    final expiresAt = DateTime.now().add(
      Duration(seconds: expiresInSeconds > 0 ? expiresInSeconds : 900),
    );
    await _writeToken(_keyAuthToken, accessToken);
    await _identifyAccount(accessToken, newLogin: newLogin);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _writeToken(_keyRefreshToken, refreshToken);
    } else {
      await _writeToken(_keyRefreshToken, null);
    }
    await _prefs.setInt(
      _keyTokenExpiresAt,
      expiresAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clearAuthSession({bool keepLocalAccount = false}) async {
    await _writeToken(_keyAuthToken, null);
    await _writeToken(_keyRefreshToken, null);
    if (!keepLocalAccount) await _prefs.remove('local_account_id');
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
