import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A passive desktop tooltip without OverlayPortal semantics reparenting.
/// The owning control supplies its accessible description.
class WindowsTooltip extends StatefulWidget {
  const WindowsTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;

  @override
  State<WindowsTooltip> createState() => _WindowsTooltipState();
}

class _WindowsTooltipState extends State<WindowsTooltip> {
  Timer? _timer;
  OverlayEntry? _entry;
  bool _hovered = false;
  bool _focused = false;
  ScrollPosition? _scroll;

  void _update() {
    _timer?.cancel();
    if (!_hovered && !_focused) {
      _hide();
    } else if (_entry == null) {
      _timer = Timer(const Duration(milliseconds: 500), _show);
    }
  }

  void _hide() {
    _timer?.cancel();
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _show() {
    if (!mounted || (!_hovered && !_focused) || _entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final box = context.findRenderObject();
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null ||
        box is! RenderBox ||
        overlayBox is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      return;
    }
    final anchor =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final theme = Theme.of(context);
    final tooltipTheme = TooltipTheme.of(context);
    _entry = OverlayEntry(
        builder: (_) => Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomSingleChildLayout(
                    delegate: _TooltipPosition(anchor),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: tooltipTheme.padding ??
                            const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                        decoration: tooltipTheme.decoration ??
                            BoxDecoration(
                              color: theme.colorScheme.inverseSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                        child: Text(
                          widget.message,
                          style: tooltipTheme.textStyle ??
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontSize: 12,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
    overlay.insert(_entry!);
  }

  @override
  void didUpdateWidget(WindowsTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _hide();
      _update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (_scroll != scroll) {
      _scroll?.removeListener(_hide);
      _scroll = scroll;
      _scroll?.addListener(_hide);
    }
    // Invalidate old placement when resizing or changing themes.
    _hide();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_hide);
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) {
        _focused = value;
        _update();
      },
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _update();
        },
        onExit: (_) {
          _hovered = false;
          _update();
        },
        child: widget.child,
      ),
    );
  }
}

class _TooltipPosition extends SingleChildLayoutDelegate {
  const _TooltipPosition(this.anchor);
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
          maxWidth: math.min(320, math.max(0, constraints.maxWidth - 16)));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (anchor.center.dx - childSize.width / 2)
        .clamp(8.0, math.max(8.0, size.width - childSize.width - 8));
    final below = anchor.bottom + 8;
    final y = below + childSize.height <= size.height - 8
        ? below
        : math.max(8.0, anchor.top - childSize.height - 8);
    return Offset(x.toDouble(), y);
  }

  @override
  bool shouldRelayout(_TooltipPosition oldDelegate) =>
      oldDelegate.anchor != anchor;
}
