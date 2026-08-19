import 'package:flutter/material.dart';

import 'package:harmonix_apps/core/theme/theme_palette.dart';

abstract final class HarmonixColors {
  static const accent = Color(0xFFA78BFA);
  static const signal = Color(0xFF67D7F0);
  static const darkBackground = Color(0xFF07101E);
  static const darkSurface = Color(0xFF0D1727);
  static const darkCard = Color(0xFF152033);

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
    secondary: Color(0xFF00BCD4),
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
      );

  static Color _bestContrastOn(Color background) {
    final luminance = background.computeLuminance();
    final blackContrast = (luminance + 0.05) / 0.05;
    final whiteContrast = 1.05 / (luminance + 0.05);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }
}
