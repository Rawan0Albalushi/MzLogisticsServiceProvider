import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';
import 'icon_well.dart';

class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.icon,
    this.tone = IconTone.teal,
    this.trailing,
    this.footer,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final List<String> meta;
  final IconData? icon;
  final IconTone tone;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (subtitle != null && subtitle!.trim().isNotEmpty) subtitle!,
      ...meta.where((line) => line.trim().isNotEmpty),
    ];

    final body = Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, footer == null ? 14 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                IconWell(icon: icon!, tone: tone, size: IconWellSize.sm),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(onTap: onTap, child: body),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: footer,
            ),
        ],
      ),
    );
  }
}
