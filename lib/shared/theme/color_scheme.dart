import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/theme/theme_palette.dart';

abstract final class HarmonixColors {
  /// Separate readable foreground tones from the unchanged brand fill.
  static Color accessibleAccent(Color accent, Color background) {
    double contrast(Color color) {
      final a = color.computeLuminance();
      final b = background.computeLuminance();
      return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
    }

    if (contrast(accent) >= 4.5) return accent;
    final target =
        background.computeLuminance() < .5 ? Colors.white : Colors.black;
    for (var step = 1; step <= 100; step++) {
      final tone = Color.lerp(accent, target, step / 100)!;
      if (contrast(tone) >= 4.5) return tone;
    }
    return target;
  }

  static const accent = Color(0xFF7B5CFF);
  static const signal = Color(0xFF5EE6FF);
  static const darkBackground = Color(0xFF0A0F2B);
  static const darkSurface = Color(0xFF121735);
  static const darkCard = Color(0xFF1C2242);

  static const dark = ColorScheme.dark(
    primary: accent,
    secondary: signal,
    surface: darkSurface,
    onPrimary: Color(0xFF101321),
    onSurface: Colors.white,
  );

  static const light = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.black,
    secondary: Color(0xFF006779),
  );

  static ColorScheme darkFromPalette(ThemePalette palette) => ColorScheme.dark(
        primary: palette.accent,
        secondary: palette.secondary,
        surface: palette.darkSurface,
        onPrimary: _bestContrastOn(palette.accent),
        onSurface: palette.text,
      ).copyWith(
        surfaceContainer: palette.darkSurface,
        surfaceContainerHigh: palette.darkCard,
        surfaceContainerHighest: palette.darkCard,
        outline: palette.text.withValues(alpha: .42),
        outlineVariant: palette.text.withValues(alpha: .18),
      );

  static Color _bestContrastOn(Color background) {
    final luminance = background.computeLuminance();
    final blackContrast = (luminance + 0.05) / 0.05;
    final whiteContrast = 1.05 / (luminance + 0.05);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }
}
