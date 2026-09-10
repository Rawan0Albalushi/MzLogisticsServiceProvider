import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubtleFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SubtleFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: child,
    );
  }
}

CustomTransitionPage<void> subtleFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 120),
    reverseTransitionDuration: const Duration(milliseconds: 90),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
