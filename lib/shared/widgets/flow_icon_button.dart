import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:harmonix_apps/shared/widgets/windows_tooltip.dart';

/// Uses an OverlayEntry for Windows tooltips to avoid Flutter #182444.
/// The standard button, interaction and accessible description are retained.
class FlowIconButton extends IconButton {
  const FlowIconButton({
    super.key,
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.iconSize,
    super.color,
    super.autofocus,
  });

  const FlowIconButton.filled({
    super.key,
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.iconSize,
    super.color,
    super.autofocus,
  }) : super.filled();

  @override
  Widget build(BuildContext context) {
    final button = super.build(context);
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.windows ||
        tooltip == null ||
        tooltip!.isEmpty) {
      return button;
    }
    return WindowsTooltip(
      message: tooltip!,
      child: Semantics(
        tooltip: tooltip,
        child: TooltipVisibility(visible: false, child: button),
      ),
    );
  }
}
