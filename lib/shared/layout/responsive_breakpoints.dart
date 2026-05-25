import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  static const double tablet = 720;
  static const double desktop = 1100;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool useRailNavigation(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= desktop || (width >= tablet && isLandscape(context));
  }
}
