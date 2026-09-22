import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.kicker,
    required this.greeting,
    required this.subtitle,
    required this.refreshLabel,
    required this.onRefresh,
    this.updatedLabel,
  });

  final String kicker;
  final String greeting;
  final String subtitle;
  final String refreshLabel;
  final String? updatedLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.sidebarGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final copy = _HeroCopy(
              kicker: kicker,
              greeting: greeting,
              subtitle: subtitle,
              compact: constraints.maxWidth < 420,
              rtl: rtl,
            );
            final actions = _HeroActions(
              updatedLabel: updatedLabel,
              refreshLabel: refreshLabel,
              onRefresh: onRefresh,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 16),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 20),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.kicker,
    required this.greeting,
    required this.subtitle,
    required this.compact,
    required this.rtl,
  });

  final String kicker;
  final String greeting;
  final String subtitle;
  final bool compact;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rtl ? kicker : kicker.toUpperCase(),
          style: TextStyle(
            color: AppColors.coral,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: rtl ? 0 : 0.8,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          greeting,
          style: TextStyle(
            color: AppColors.white,
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.onSidebarMuted,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.updatedLabel,
    required this.refreshLabel,
    required this.onRefresh,
  });

  final String? updatedLabel;
  final String refreshLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (updatedLabel != null)
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6FBF8B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  updatedLabel!,
                  style: const TextStyle(color: AppColors.onSidebar, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            backgroundColor: AppColors.white.withValues(alpha: 0.08),
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.16)),
            minimumSize: const Size(44, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.refresh, size: 15),
          label: Text(refreshLabel),
        ),
      ],
    );
  }
}
