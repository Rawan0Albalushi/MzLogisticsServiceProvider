import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';
import 'icon_well.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = IconTone.teal,
    this.hint,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final IconTone tone;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (icon != null) IconWell(icon: icon!, tone: tone, size: IconWellSize.sm),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    );
  }
}
