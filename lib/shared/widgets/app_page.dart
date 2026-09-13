import 'package:flutter/material.dart';

import '../../core/utils/breakpoints.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Breakpoints.pagePadding(context),
      child: child,
    );
  }
}
