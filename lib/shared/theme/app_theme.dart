import 'package:flutter/material.dart';

import 'color_scheme.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: HarmonixColors.dark,
        scaffoldBackgroundColor: HarmonixColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: HarmonixColors.darkSurface,
          selectedItemColor: HarmonixColors.accent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          color: HarmonixColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: HarmonixColors.accent,
          inactiveTrackColor: Colors.white24,
          thumbColor: HarmonixColors.accent,
          overlayColor: HarmonixColors.accent.withOpacity(0.2),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: _textTheme(Colors.white),
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
        bodyMedium: TextStyle(color: color.withOpacity(0.85), fontSize: 14),
        bodySmall: TextStyle(color: color.withOpacity(0.6), fontSize: 12),
      );
}
