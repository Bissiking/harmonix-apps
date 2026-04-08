import 'package:flutter/material.dart';

abstract final class HarmonixColors {
  static const accent = Color(0xFF7C4DFF); // Purple
  static const darkBackground = Color(0xFF0E0E14);
  static const darkSurface = Color(0xFF1A1A24);
  static const darkCard = Color(0xFF22223A);

  static const dark = ColorScheme.dark(
    primary: accent,
    secondary: Color(0xFF00E5FF),
    surface: darkSurface,
    onPrimary: Colors.white,
    onSurface: Colors.white,
  );

  static const light = ColorScheme.light(
    primary: accent,
    secondary: Color(0xFF00BCD4),
  );
}
