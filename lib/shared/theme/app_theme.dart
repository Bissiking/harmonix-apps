import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';
import 'package:harmonix_apps/shared/theme/page_transitions.dart';

abstract final class AppTheme {
  static ThemeData dark(ThemePalette palette) => ThemeData(
        useMaterial3: true,
        colorScheme: HarmonixColors.darkFromPalette(palette),
        scaffoldBackgroundColor: palette.darkBackground,
        canvasColor: palette.darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: palette.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: palette.text),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: palette.darkSurface,
          selectedItemColor: palette.accent,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: palette.darkSurface,
          indicatorColor: palette.accent.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? palette.accent
                  : palette.text.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? palette.accent
                  : palette.text.withValues(alpha: 0.58),
            ),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: palette.darkSurface,
          selectedIconTheme: IconThemeData(color: palette.accent),
          selectedLabelTextStyle: TextStyle(
            color: palette.accent,
            fontWeight: FontWeight.w600,
          ),
          unselectedIconTheme: const IconThemeData(color: Colors.white54),
          unselectedLabelTextStyle:
              const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        cardTheme: CardThemeData(
          color: palette.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          thickness: 1,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: palette.accent,
          inactiveTrackColor: Colors.white24,
          thumbColor: palette.accent,
          overlayColor: palette.accent.withValues(alpha: 0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: palette.darkCard,
          hintStyle: TextStyle(color: palette.text.withValues(alpha: 0.45)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.accent),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: palette.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        iconTheme: IconThemeData(color: palette.text),
        textTheme: _textTheme(palette.text),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: HarmonixPageTransitionsBuilder(),
            TargetPlatform.iOS: HarmonixPageTransitionsBuilder(),
            TargetPlatform.macOS: HarmonixPageTransitionsBuilder(),
            TargetPlatform.windows: HarmonixPageTransitionsBuilder(),
            TargetPlatform.linux: HarmonixPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: HarmonixColors.light.copyWith(
          surface: const Color(0xFFFAFAFC),
          surfaceContainerHighest: const Color(0xFFF0F0F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: HarmonixColors.accent,
          unselectedItemColor: Colors.black38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: HarmonixColors.accent),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.black12,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        textTheme: _textTheme(Colors.black87),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: HarmonixPageTransitionsBuilder(),
            TargetPlatform.iOS: HarmonixPageTransitionsBuilder(),
            TargetPlatform.macOS: HarmonixPageTransitionsBuilder(),
            TargetPlatform.windows: HarmonixPageTransitionsBuilder(),
            TargetPlatform.linux: HarmonixPageTransitionsBuilder(),
          },
        ),
      );

  static TextTheme _textTheme(Color color) => TextTheme(
        displaySmall:
            TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 36),
        headlineMedium:
            TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 28),
        headlineSmall:
            TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 20),
        titleLarge:
            TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 18),
        titleMedium:
            TextStyle(fontWeight: FontWeight.w500, color: color, fontSize: 16),
        bodyMedium:
            TextStyle(color: color.withValues(alpha: 0.85), fontSize: 14),
        bodySmall: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12),
      );
}
