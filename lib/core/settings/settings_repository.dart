import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

const _keyServerUrl = 'server_url';
const _keyAuthToken = 'auth_token';
const _keyThemeJson = 'theme_json';
const _keyRiftSessionId = 'rift_session_id';
const _keyRiftDeviceId = 'rift_device_id';
const _keyCastLastDevice = 'cast_last_device';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? _defaultServerUrl;

  Future<void> setServerUrl(String url) => _prefs.setString(_keyServerUrl, url);

  String? get authToken => _prefs.getString(_keyAuthToken) ?? _defaultAuthToken;

  Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_keyAuthToken);
      return;
    }
    await _prefs.setString(_keyAuthToken, token);
  }

  String? get themeJson => _prefs.getString(_keyThemeJson);

  Future<void> setThemeJson(String json) =>
      _prefs.setString(_keyThemeJson, json);

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
        defaultValue: 'https://dev.mhemery.fr',
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
