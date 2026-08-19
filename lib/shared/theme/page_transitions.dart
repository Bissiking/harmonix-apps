import 'package:flutter/material.dart';

/// Transition de page Harmonix : léger fondu + léger glissement vertical.
///
/// Appliqué à toutes les plateformes pour une navigation uniforme
/// (mobile, tablette, desktop).
class HarmonixPageTransitionsBuilder extends PageTransitionsBuilder {
  const HarmonixPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
