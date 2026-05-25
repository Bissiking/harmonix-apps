import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

const _keyServerUrl = 'server_url';
const _keyAuthToken = 'auth_token';
const _keyThemeJson = 'theme_json';

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

  static String get _defaultServerUrl => const String.fromEnvironment(
        'HARMONIX_API_BASE_URL',
        defaultValue: 'https://mhemery.fr',
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
