import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme mode updates reactively and persists', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(preferences),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);

    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(preferences.getString('theme_mode'), 'dark');
  });
}
