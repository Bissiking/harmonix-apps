import 'package:flutter/material.dart';

class ThemePalette {
  const ThemePalette({
    required this.accent,
    required this.secondary,
    required this.text,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkCard,
    required this.isAmoled,
  });

  final Color accent;
  final Color secondary;
  final Color text;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkCard;
  final bool isAmoled;

  static const ThemePalette fallback = ThemePalette(
    accent: Color(0xFF7C4DFF),
    secondary: Color(0xFF00E5FF),
    text: Colors.white,
    darkBackground: Color(0xFF0E0E14),
    darkSurface: Color(0xFF1A1A24),
    darkCard: Color(0xFF22223A),
    isAmoled: false,
  );

  ThemePalette withAmoled(bool value) {
    if (!value) return this;
    return ThemePalette(
      accent: accent,
      secondary: secondary,
      text: text,
      darkBackground: Colors.black,
      darkSurface: const Color(0xFF0A0A0A),
      darkCard: const Color(0xFF111111),
      isAmoled: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'accent': _toHex(accent),
        'secondary': _toHex(secondary),
        'text': _toHex(text),
        'darkBackground': _toHex(darkBackground),
        'darkSurface': _toHex(darkSurface),
        'darkCard': _toHex(darkCard),
        'isAmoled': isAmoled,
      };

  factory ThemePalette.fromJson(Map<String, dynamic> json) {
    final source = _themeMap(json);
    final base = ThemePalette(
      accent:
          _parseColor(source, ['gold', 'accent', 'primary'], fallback.accent),
      secondary: _parseColor(source, ['secondary'], fallback.secondary),
      text: _parseColor(source, ['text', 'onSurface'], fallback.text),
      darkBackground: _parseColor(
        source,
        ['bg_dark', 'darkBackground', 'background'],
        fallback.darkBackground,
      ),
      darkSurface: _parseColor(source, ['bg_surface', 'darkSurface', 'surface'],
          fallback.darkSurface),
      darkCard: _parseColor(
          source, ['bg_card', 'darkCard', 'card'], fallback.darkCard),
      isAmoled: json['isAmoled'] == true || json['amoled'] == true,
    );
    return base.isAmoled ? base.withAmoled(true) : base;
  }

  static Map<String, dynamic> _themeMap(Map<String, dynamic> json) {
    final nested = json['theme_colors'];
    if (nested is Map<String, dynamic>) return nested;
    return json;
  }

  static Color _parseColor(
    Map<String, dynamic> json,
    List<String> keys,
    Color fallbackColor,
  ) {
    for (final key in keys) {
      final value = json[key];
      final parsed = _tryParseColor(value);
      if (parsed != null) return parsed;
    }
    return fallbackColor;
  }

  static Color? _tryParseColor(Object? value) {
    if (value is int) return Color(value);
    if (value is! String) return null;
    var input = value.trim();
    if (input.isEmpty) return null;
    if (input.startsWith('#')) input = input.substring(1);
    if (input.length == 6) input = 'FF$input';
    final parsed = int.tryParse(input, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  static String _toHex(Color color) {
    final value = color.toARGB32();
    return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
