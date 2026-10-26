import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension EnterAnimation on Widget {
  /// Gentle rise-and-fade entrance. Returns the plain child when the
  /// user asked for reduced motion.
  Widget enter(BuildContext context, {int delayMs = 0}) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: const Duration(milliseconds: 420), curve: Curves.easeOut)
        .slideY(
          begin: 0.35,
          end: 0,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
  }
}

/// Soft fade-and-settle page transition used across the app.
PageRoute<T> softRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
