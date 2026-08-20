import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/core/theme/theme_sync_service.dart';

final themeSyncServiceProvider = Provider<ThemeSyncService>((ref) {
  return ThemeSyncService(
    dio: ref.watch(dioProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

class ThemeController extends StateNotifier<ThemePalette> {
  ThemeController(this._ref) : super(ThemePalette.fallback);

  final Ref _ref;

  ThemeSyncService get _service => _ref.read(themeSyncServiceProvider);

  Future<void> initFromCache() async {
    state = await _service.loadCachedOrFallback();
  }

  Future<void> syncFromApi() async {
    state = await _service.syncFromApi();
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemePalette>(
  (ref) => ThemeController(ref),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._settings) : super(_settings.themeMode);

  final SettingsRepository _settings;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _settings.setThemeMode(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(settingsRepositoryProvider)),
);
