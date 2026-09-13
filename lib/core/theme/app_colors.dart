import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF142426);
  static const Color teal = Color(0xFF00A6A6);
  static const Color teal800 = Color(0xFF008C8C);
  static const Color tealMid = Color(0xFF006666);
  static const Color tealDeep = Color(0xFF003D3D);
  static const Color tealSoft = Color(0xFFE3F6F6);
  static const Color coral = Color(0xFFFFC107);
  static const Color coralDeep = Color(0xFFC49200);
  static const Color coralSoft = Color(0xFFFFF6E0);
  static const Color onAccent = Color(0xFF142426);
  static const Color surface = Color(0xFFF3F8F8);
  static const Color border = Color(0xFFD4E3E3);
  static const Color hoverBorder = Color(0xFFB7CECE);
  static const Color rowHover = Color(0xFFE7F5F5);
  static const Color muted = Color(0xFF5C6D6D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sidebar = tealDeep;
  static const Color sidebarHover = Color(0xFF0A5555);
  static const Color onSidebar = Color(0xFFF3FFFF);
  static const Color onSidebarMuted = Color(0xFFB5D6D6);
  static const Color success = Color(0xFF2F6B4F);
  static const Color successSoft = Color(0xFFE5F2EA);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFEECEC);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFF7EFD9);
  static const Color info = Color(0xFF1F6F8F);
  static const Color infoSoft = Color(0xFFE4F3F6);
  static const Color chipBg = Color(0xFFE8F2F2);
  static const Color accentSoft = Color(0x33FFC107);
  static const Color focusRing = Color(0x3300A6A6);
  static const double radius = 12;

  static const Color navy = teal;
  static const Color amber = coral;
  static const Color accentFrom = Color(0xFF2EC4C4);
  static const Color accentTo = teal;
  static const Color navyMuted = onSidebarMuted;

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), coral],
    stops: [0.05, 0.86],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [teal800, tealMid, tealDeep],
    stops: [0, 0.42, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2EC4C4), teal],
  );
}
