import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../providers/session_provider.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? trailing;

  bool _isMostlyLtr(String value) {
    return RegExp(r'^[\x00-\x7F\-_/.:#\s]+$').hasMatch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = !Breakpoints.isDesktop(context) || constraints.maxWidth < 720;
        if (stacked || actions.isEmpty && trailing == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
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
            Expanded(child: titleBlock),
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
        color: const Color(0xFFF8F1E4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
      ),
      child: Text(context.tr(messageKey), style: const TextStyle(height: 1.45)),
    );
  }
}
