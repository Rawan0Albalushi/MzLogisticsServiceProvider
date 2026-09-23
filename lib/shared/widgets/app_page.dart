import 'package:flutter/material.dart';

import '../../core/utils/breakpoints.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child, this.physics});

  final Widget child;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = Breakpoints.contentMaxWidth(context);
        final width = constraints.maxWidth < cap ? constraints.maxWidth : cap;
        return ListView(
          primary: true,
          physics: physics,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: Padding(
                  padding: Breakpoints.pagePadding(context),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
