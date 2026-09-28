import 'package:flutter/material.dart';

/// Subtle fade + slide-up used when a card first appears (e.g. after adding an
/// email). Because list items are keyed, existing cards never replay it.
class AppearAnimation extends StatelessWidget {
  const AppearAnimation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}
