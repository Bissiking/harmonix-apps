// flow_appearance.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/shared/theme/flow_tokens.dart';

enum FlowAppearance { midnight, aurora, daylight, night }

extension FlowAppearanceData on FlowAppearance {
  String get label => switch (this) {
        FlowAppearance.midnight => 'Harmonix Midnight',
        FlowAppearance.aurora => 'Harmonix Aurora',
        FlowAppearance.daylight => 'Harmonix Daylight',
        FlowAppearance.night => 'Harmonix Night',
      };
  ThemePalette get palette => ThemePalette(
      accent: this == FlowAppearance.night
          ? FlowTokens.lavender
          : this == FlowAppearance.aurora
              ? FlowTokens.cyan
              : FlowTokens.violet,
      secondary: this == FlowAppearance.night
          ? const Color(0xFF9EA8D7)
          : FlowTokens.cyan,
      text: const Color(0xFFF2F1FA),
      darkBackground: this == FlowAppearance.night
          ? const Color(0xFF06091A)
          : FlowTokens.midnight,
      darkSurface: this == FlowAppearance.night
          ? const Color(0xFF0D1025)
          : const Color(0xFF121735),
      darkCard: this == FlowAppearance.aurora
          ? const Color(0xFF1D2948)
          : const Color(0xFF1C2242),
      isAmoled: false);
}

class AppearanceController extends StateNotifier<FlowAppearance> {
  AppearanceController(this.settings) : super(_initial(settings));
  final SettingsRepository settings;
  static FlowAppearance _initial(SettingsRepository settings) {
    for (final appearance in FlowAppearance.values) {
      if (appearance.name == settings.appearance) return appearance;
    }
    return settings.themeMode == ThemeMode.light
        ? FlowAppearance.daylight
        : FlowAppearance.midnight;
  }

  Future<void> select(FlowAppearance appearance) async {
    await settings.setAppearance(appearance.name);
    state = appearance;
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceController, FlowAppearance>(
        (ref) => AppearanceController(ref.watch(settingsRepositoryProvider)));
final appearanceRevisionProvider = StateProvider<int>((ref) => 0);
