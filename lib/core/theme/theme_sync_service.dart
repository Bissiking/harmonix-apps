import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_palette.dart';

class ThemeSyncService {
  ThemeSyncService({
    required Dio dio,
    required SettingsRepository settings,
  })  : _dio = dio,
        _settings = settings;

  final Dio _dio;
  final SettingsRepository _settings;

  Future<ThemePalette> loadCachedOrFallback() async {
    final raw = _settings.themeJson;
    if (raw == null || raw.isEmpty) return ThemePalette.fallback;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ThemePalette.fromJson(decoded);
      }
    } catch (_) {}
    return ThemePalette.fallback;
  }

  Future<ThemePalette> syncFromApi() async {
    final fromTheme = await _fetchThemeEndpoint();
    if (fromTheme != null) {
      await _settings.setThemeJson(jsonEncode(fromTheme.toJson()));
      return fromTheme;
    }

    final fromBootstrap = await _fetchThemeFromBootstrap();
    if (fromBootstrap != null) {
      await _settings.setThemeJson(jsonEncode(fromBootstrap.toJson()));
      return fromBootstrap;
    }

    return loadCachedOrFallback();
  }

  Future<ThemePalette?> _fetchThemeEndpoint() async {
    try {
      final response = await _dio.get('/api/harmonix/apps/v2/theme');
      final data = response.data;
      if (data is Map<String, dynamic>) return ThemePalette.fromJson(data);
    } catch (_) {}
    return null;
  }

  Future<ThemePalette?> _fetchThemeFromBootstrap() async {
    try {
      final response = await _dio.get('/api/harmonix/apps/v2/bootstrap');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final theme = data['theme'];
      if (theme is Map<String, dynamic>) return ThemePalette.fromJson(theme);
    } catch (_) {}
    return null;
  }
}
