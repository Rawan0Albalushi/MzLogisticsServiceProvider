import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';
import '../../core/utils/breakpoints.dart';
import '../providers/session_provider.dart';
import 'icon_well.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.trailing,
    this.icon,
    this.tone,
    this.hideIcon = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? trailing;
  final IconData? icon;
  final IconTone? tone;
  final bool hideIcon;

  bool _isMostlyLtr(String value) {
    return RegExp(r'^[\x00-\x7F\-_/.:#\s]+$').hasMatch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final visual = PageVisuals.of(path);
    final resolvedIcon = icon ?? visual.icon;
    final resolvedTone = tone ?? visual.tone;
    final compact = MediaQuery.sizeOf(context).width < 400;

    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
          fontSize: compact ? 20 : 24,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.muted,
          height: 1.45,
        );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: titleStyle,
          textDirection: _isMostlyLtr(title) ? TextDirection.ltr : null,
          textAlign: TextAlign.start,
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: subtitleStyle,
            textDirection: _isMostlyLtr(subtitle!) ? TextDirection.ltr : null,
            textAlign: TextAlign.start,
          ),
        ],
      ],
    );

    final lead = hideIcon
        ? titleBlock
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconWell(
                icon: resolvedIcon,
                tone: resolvedTone,
                size: compact ? IconWellSize.md : IconWellSize.lg,
              ),
              const SizedBox(width: 12),
              Expanded(child: titleBlock),
            ],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = !Breakpoints.isDesktop(context) || constraints.maxWidth < 720;
        if (stacked || actions.isEmpty && trailing == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              lead,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
              if (trailing != null) ...[
                const SizedBox(height: 12),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: lead),
            const SizedBox(width: 16),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [...actions, ?trailing],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PendingReviewBanner extends ConsumerWidget {
  const PendingReviewBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sessionProvider).user?.organization?.status;
    final messageKey = switch (status) {
      'rejected' => 'auth.restrictedRejected',
      'suspended' => 'auth.restrictedSuspended',
      _ => 'auth.pendingReview',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          IconWell(
            icon: Icons.hourglass_top_rounded,
            tone: IconTone.warning,
            size: IconWellSize.sm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.tr(messageKey), style: const TextStyle(height: 1.45)),
          ),
        ],
      ),
    );
  }
}
