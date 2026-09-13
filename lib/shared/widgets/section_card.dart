import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';
import 'icon_well.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.tone = IconTone.teal,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final IconTone tone;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    IconWell(icon: icon!, tone: tone, size: IconWellSize.sm),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  bool _isMostlyLtr(String text) {
    return RegExp(r'^[\x00-\x7F\-_/.:#\s]+$').hasMatch(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
              textDirection: _isMostlyLtr(value) ? TextDirection.ltr : null,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
