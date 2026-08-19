import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harmonix_apps/core/theme/theme_palette.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

void main() {
  test('primary foreground keeps accessible contrast for server accents', () {
    const accents = [
      Color(0xFFA78BFA),
      Color(0xFF6750A4),
      Color(0xFF777777),
      Color(0xFFE9D5FF),
      Color(0xFF231942),
    ];

    for (final accent in accents) {
      final scheme = HarmonixColors.darkFromPalette(
        ThemePalette(
          accent: accent,
          secondary: const Color(0xFF67D7F0),
          text: Colors.white,
          darkBackground: const Color(0xFF07101E),
          darkSurface: const Color(0xFF0D1727),
          darkCard: const Color(0xFF152033),
          isAmoled: false,
        ),
      );

      expect(_contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5));
    }
  });

  test('light theme primary foreground is accessible', () {
    expect(
      _contrast(HarmonixColors.light.primary, HarmonixColors.light.onPrimary),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  return (math.max(firstLuminance, secondLuminance) + 0.05) /
      (math.min(firstLuminance, secondLuminance) + 0.05);
}
