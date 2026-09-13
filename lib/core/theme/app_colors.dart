import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF16182B);
  static const Color navy = Color(0xFF161B3C);
  static const Color accentFrom = Color(0xFF5BA3FF);
  static const Color accentTo = Color(0xFF4F46E5);
  static const Color amber = accentTo;
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3F4F9);
  static const Color border = Color(0xFFD4D7E6);
  static const Color muted = Color(0xFF5A5E76);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFF161B3C);
  static const Color sidebarHover = Color(0xFF22285A);
  static const Color navyMuted = Color(0xFFA8B0D4);
  static const Color success = Color(0xFF2F6B4F);
  static const Color danger = Color(0xFF8B2E2E);
  static const Color warning = Color(0xFF9A6B1F);
  static const Color info = Color(0xFF3D4F9C);
  static const Color chipBg = Color(0xFFE8EAF4);
  static const Color accentSoft = Color(0x1A4F46E5);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentFrom, accentTo],
    stops: [0.05, 0.72],
  );
}
