import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.organization = false});

  final String? status;
  final bool organization;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = organization ? l10n.organizationStatus(status) : l10n.status(status);
    final tone = _tone(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _tone(String? value) {
    switch (value) {
      case 'published':
      case 'accepted':
      case 'completed':
      case 'delivered':
      case 'available':
      case 'paid':
      case 'active':
      case 'earning_released':
      case 'payout_completed':
        return AppColors.success;
      case 'in_progress':
      case 'in_transit':
      case 'assigned':
      case 'loaded':
      case 'arrived':
      case 'arrived_at_pickup':
      case 'processing':
      case 'on_trip':
      case 'in_use':
        return AppColors.info;
      case 'submitted':
      case 'pending':
      case 'pending_dispatch':
      case 'unassigned':
      case 'issued':
      case 'job_earning':
      case 'payout_reserved':
        return AppColors.warning;
      case 'cancelled':
      case 'rejected':
      case 'withdrawn':
      case 'failed':
      case 'inactive':
      case 'suspended':
      case 'void':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }
}
