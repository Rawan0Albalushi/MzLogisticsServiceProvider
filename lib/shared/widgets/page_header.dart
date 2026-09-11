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

  @override
  Widget build(BuildContext context) {
    final desktop = Breakpoints.isDesktop(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
        ],
      ],
    );

    if (!desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
        Wrap(spacing: 8, runSpacing: 8, children: [...actions, ?trailing]),
      ],
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
      child: Text(context.tr(messageKey)),
    );
  }
}
