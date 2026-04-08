import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

const _keyServerUrl = 'server_url';
const _defaultServerUrl = 'http://localhost:3000';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? _defaultServerUrl;

  Future<void> setServerUrl(String url) =>
      _prefs.setString(_keyServerUrl, url);
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden after SharedPreferences.getInstance()',
  );
}
