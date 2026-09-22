import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';

enum IconWellSize { sm, md, lg }

class IconWell extends StatelessWidget {
  const IconWell({
    super.key,
    required this.icon,
    this.tone = IconTone.teal,
    this.size = IconWellSize.md,
  });

  final IconData icon;
  final IconTone tone;
  final IconWellSize size;

  double get _box => switch (size) {
        IconWellSize.sm => 32,
        IconWellSize.md => 40,
        IconWellSize.lg => 48,
      };

  double get _icon => switch (size) {
        IconWellSize.sm => 16,
        IconWellSize.md => 20,
        IconWellSize.lg => 24,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _box,
      height: _box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
      child: Icon(icon, size: _icon, color: tone.foreground),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFC107),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'MX',
        style: TextStyle(
          color: AppColors.onAccent,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.33,
          height: 1,
        ),
      ),
    );
  }
}
