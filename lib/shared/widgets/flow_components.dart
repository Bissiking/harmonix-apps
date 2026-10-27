// flow_components.dart
import 'package:flutter/material.dart';
import 'package:harmonix_apps/shared/theme/flow_tokens.dart';

class FlowEmptyState extends StatelessWidget {
  const FlowEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(FlowTokens.gutter),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                if (action != null) ...[const SizedBox(height: 24), action!],
              ]))));
}

Future<void> runFlowAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is StateError
              ? error.message.toString()
              : 'Action impossible. Réessaie.')));
    }
  }
}

class FlowFocusTile extends StatefulWidget {
  const FlowFocusTile(
      {super.key,
      required this.child,
      required this.onPressed,
      this.autofocus = false});
  final Widget child;
  final VoidCallback onPressed;
  final bool autofocus;
  @override
  State<FlowFocusTile> createState() => _FlowFocusTileState();
}

class _FlowFocusTileState extends State<FlowFocusTile> {
  bool focused = false;
  @override
  Widget build(BuildContext context) => Focus(
      onFocusChange: (value) {
        setState(() => focused = value);
        if (value) {
          Scrollable.ensureVisible(context,
              alignment: .5,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : FlowTokens.motion);
        }
      },
      canRequestFocus: false,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              autofocus: widget.autofocus,
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(FlowTokens.radius),
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(FlowTokens.radius),
                      border: Border.all(
                          width: 3,
                          color: focused
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent)),
                  padding: const EdgeInsets.all(8),
                  child: widget.child))));
}
