import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

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
    return _fadePage(animation, secondaryAnimation, child);
  }
}

CustomTransitionPage<void> subtleFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: ColoredBox(
      color: AppColors.surface,
      child: child,
    ),
    opaque: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 120),
    reverseTransitionDuration: const Duration(milliseconds: 90),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _fadePage(animation, secondaryAnimation, child);
    },
  );
}

Widget _fadePage(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
    child: FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
      ),
      child: child,
    ),
  );
}
