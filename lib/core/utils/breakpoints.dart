import 'package:flutter/material.dart';

class Breakpoints {
  const Breakpoints._();

  static const double compact = 760;
  static const double medium = 1100;
  static const double wide = 1440;

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
    return isLarge(context) ? 272 : 248;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1920) return 1760;
    if (width >= 1600) return 1520;
    if (width >= 1280) return 1280;
    return 1100;
  }
}
