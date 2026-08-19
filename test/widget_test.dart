import 'package:flutter_test/flutter_test.dart' show test, expect;

import 'package:harmonix_apps/shared/layout/content_constraints.dart';
import 'package:harmonix_apps/shared/layout/responsive_breakpoints.dart';

void main() {
  test('ResponsiveBreakpoints expose les breakpoints attendus', () {
    expect(ResponsiveBreakpoints.tablet, 720);
    expect(ResponsiveBreakpoints.desktop, 1100);
  });

  test('contentMaxWidth est la largeur de contenu partagée', () {
    expect(contentMaxWidth, 980.0);
  });
}
