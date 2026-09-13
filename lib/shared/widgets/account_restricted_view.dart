import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../providers/session_provider.dart';
import 'app_button.dart';
import 'app_page.dart';
import 'confirm_dialog.dart';
import 'section_card.dart';
import 'status_badge.dart';

class AccountRestrictedView extends ConsumerStatefulWidget {
  const AccountRestrictedView({super.key});

  @override
  ConsumerState<AccountRestrictedView> createState() => _AccountRestrictedViewState();
}

class _AccountRestrictedViewState extends ConsumerState<AccountRestrictedView> {
  var _refreshing = false;

  String _titleKey(SessionState session) {
    final status = session.user?.organization?.status;
    return switch (status) {
      'rejected' => 'auth.restrictedRejectedTitle',
      'suspended' => 'auth.restrictedSuspendedTitle',
      _ => 'auth.pendingReviewTitle',
    };
  }

  String _bodyKey(SessionState session) {
    final status = session.user?.organization?.status;
    return switch (status) {
      'rejected' => 'auth.restrictedRejected',
      'suspended' => 'auth.restrictedSuspended',
      _ => 'auth.pendingReview',
    };
  }

  Future<void> _refreshStatus() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await ref.read(sessionProvider.notifier).refreshUser();
      if (!mounted) {
        return;
      }
      final session = ref.read(sessionProvider);
      if (!session.canOperate) {
        showAppSnack(context, context.tr('auth.statusUnchanged'));
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          error.message == 'network' ? context.tr('common.networkError') : error.message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final organization = session.user?.organization;
    final canViewCompany = session.permissions.can(AppPermissions.companyManage);

    return AppPage(
      child: ListView(
      children: [
        Text(
          context.tr(_titleKey(session)),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    session.user?.organization?.isRejected == true || session.user?.organization?.isSuspended == true
                        ? Icons.lock_outline
                        : Icons.hourglass_empty_outlined,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      organization?.name ?? session.user?.name ?? context.tr('app.name'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusBadge(status: organization?.status, organization: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(_bodyKey(session)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (session.isPendingReview) ...[
                const SizedBox(height: 10),
                Text(
                  context.tr('auth.pendingReviewHint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.45),
                ),
              ],
              const SizedBox(height: 20),
              AppButton(
                label: context.tr('auth.refreshStatus'),
                loading: _refreshing,
                expanded: true,
                onPressed: _refreshStatus,
              ),
              if (canViewCompany) ...[
                const SizedBox(height: 10),
                AppButton(
                  label: context.tr('company.title'),
                  outlined: true,
                  expanded: true,
                  onPressed: () => context.go('/company'),
                ),
              ],
            ],
          ),
        ),
      ],
      ),
    );
  }
}
