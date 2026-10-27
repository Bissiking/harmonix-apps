import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmonix_apps/shared/widgets/flow_icon_button.dart';

void main() {
  testWidgets('Windows tooltips keep descriptions and avoid OverlayPortal',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final semantics = tester.ensureSemantics();
    try {
      var presses = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Center(
        child: FlowIconButton(
          tooltip: 'Écouter',
          icon: const Icon(Icons.play_arrow),
          onPressed: () => presses++,
        ),
      ))));
      await tester.pumpAndSettle();
      final button = find.byType(FlowIconButton);
      expect(tester.getSemantics(button).getSemanticsData().tooltip, 'Écouter');
      expect(find.byType(OverlayPortal), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 501));
      await tester.pump();
      expect(find.text('Écouter'), findsOneWidget);
      expect(find.byType(OverlayPortal), findsNothing);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('Écouter'), findsNothing);
      await tester.tap(button);
      expect(presses, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('pending Windows tooltips do not outlive their buttons',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Center(
        child: FlowIconButton.filled(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete),
            onPressed: () {}),
      ))));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(FlowIconButton)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Supprimer'), findsNothing);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
