// harmonix_mark.dart
import 'package:flutter/material.dart';
import 'package:harmonix_apps/shared/theme/flow_tokens.dart';

/// The same 128-unit geometry is stored in assets/branding/harmonix.svg.
class HarmonixMark extends StatelessWidget {
  const HarmonixMark(
      {super.key, this.size = 48, this.night = false, this.monochrome});
  final double size;
  final bool night;
  final Color? monochrome;
  @override
  Widget build(BuildContext context) => Semantics(
      label: night ? 'Harmonix Night' : 'Harmonix',
      image: true,
      child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _MarkPainter(night, monochrome))));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.night, this.monochrome);
  final bool night;
  final Color? monochrome;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 128, size.height / 128);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (monochrome != null) {
      paint.color = monochrome!;
    } else {
      paint.shader = const LinearGradient(
              colors: [FlowTokens.violet, FlowTokens.lavender, FlowTokens.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
          .createShader(const Rect.fromLTWH(20, 20, 88, 90));
    }
    canvas.drawPath(
        Path()
          ..moveTo(28, 28)
          ..lineTo(28, 100),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(100, night ? 48 : 28)
          ..lineTo(100, 100),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(28, 76)
          ..cubicTo(48, 32, 78, 108, 100, 60),
        paint);
    if (night) {
      final moon = Path()
        ..moveTo(112, 8)
        ..cubicTo(83, 8, 83, 43, 112, 43)
        ..cubicTo(96, 39, 96, 14, 112, 8)
        ..close();
      canvas.drawPath(moon, Paint()..color = monochrome ?? FlowTokens.lavender);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.night != night || oldDelegate.monochrome != monochrome;
}
