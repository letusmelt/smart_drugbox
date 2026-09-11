import 'package:flutter/material.dart';

/// A pill button with visible pressed feedback for touch, mouse and keyboard.
class PressButton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;
  final VoidCallback onPressed;
  final Widget child;
  const PressButton({
    super.key,
    required this.padding,
    required this.color,
    required this.borderRadius,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: ButtonStyle(
      padding: WidgetStatePropertyAll(padding),
      minimumSize: const WidgetStatePropertyAll(Size(44, 48)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? Color.alphaBlend(const Color(0x26000000), color)
            : color,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered)
            ? const Color(0x10000000)
            : Colors.transparent,
      ),
      animationDuration: const Duration(milliseconds: 90),
      splashFactory: NoSplash.splashFactory,
    ),
    child: child,
  );
}
