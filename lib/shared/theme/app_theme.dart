import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

abstract final class AppTheme {
  static ThemeData dark(ThemePalette palette) => ThemeData(
        useMaterial3: true,
        colorScheme: HarmonixColors.darkFromPalette(palette),
        scaffoldBackgroundColor: palette.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: palette.darkSurface,
          selectedItemColor: palette.accent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: palette.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: palette.accent,
          inactiveTrackColor: Colors.white24,
          thumbColor: palette.accent,
          overlayColor: palette.accent.withValues(alpha: 0.2),
        ),
        iconTheme: IconThemeData(color: palette.text),
        textTheme: _textTheme(palette.text),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: HarmonixColors.light,
        textTheme: _textTheme(Colors.black87),
      );

  static TextTheme _textTheme(Color color) => TextTheme(
        headlineMedium:
            TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 24),
        titleLarge:
            TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 18),
        titleMedium:
            TextStyle(fontWeight: FontWeight.w500, color: color, fontSize: 16),
        bodyMedium:
            TextStyle(color: color.withValues(alpha: 0.85), fontSize: 14),
        bodySmall: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12),
      );
}
