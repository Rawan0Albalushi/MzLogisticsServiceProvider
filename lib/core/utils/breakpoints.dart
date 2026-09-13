import 'package:flutter/material.dart';

class Breakpoints {
  const Breakpoints._();

  static const double phone = 600;
  static const double compact = 760;
  static const double medium = 1100;
  static const double wide = 1440;

  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < phone;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= compact;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= medium;
  }

  static bool isLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= wide;
  }

  static double sidebarWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1920) return 280;
    if (width >= wide) return 272;
    return 260;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1920) return 1760;
    if (width >= 1600) return 1520;
    if (width >= 1280) return 1280;
    return 1100;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return const EdgeInsets.fromLTRB(12, 12, 12, 16);
    if (width < compact) return const EdgeInsets.fromLTRB(16, 16, 16, 20);
    if (width >= wide) return const EdgeInsets.fromLTRB(28, 24, 28, 28);
    return const EdgeInsets.fromLTRB(20, 20, 20, 24);
  }

  static int metricColumns(double width) {
    if (width >= 1400) return 4;
    if (width >= 980) return 3;
    if (width >= 420) return 2;
    return 1;
  }
}
