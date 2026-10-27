// harmonix_logo.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';

/// The 3D Harmonix mark shipped in `assets/images`.
///
/// Picks the Night variant (crescent) automatically when the active
/// appearance is [FlowAppearance.night]; pass [night] to force a variant.
class HarmonixLogo extends ConsumerWidget {
  const HarmonixLogo({super.key, this.size = 48, this.night});

  static const String dayAsset = 'assets/images/harmonix.png';
  static const String nightAsset = 'assets/images/harmonix_night.png';

  final double size;
  final bool? night;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNight =
        night ?? ref.watch(appearanceProvider) == FlowAppearance.night;
    return Semantics(
      label: isNight ? 'Harmonix Night' : 'Harmonix',
      image: true,
      child: Image.asset(
        isNight ? nightAsset : dayAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}
