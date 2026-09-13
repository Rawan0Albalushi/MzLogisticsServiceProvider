import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/dashboard.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/account_restricted_view.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../jobs/presentation/jobs_screen.dart';
import '../../trips/presentation/trips_screen.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardSnapshot>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isAccountRestricted) {
      return const AccountRestrictedView();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: AsyncBody(
        value: ref.watch(dashboardProvider),
        onRetry: () => ref.invalidate(dashboardProvider),
        builder: (data) {
          return ListView(
            children: [
              PageHeader(
                title: context.tr('dashboard.title'),
                subtitle: context.tr('dashboard.subtitle'),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = Breakpoints.metricColumns(constraints.maxWidth);
                  final gap = 12.0;
                  final itemWidth = (constraints.maxWidth - (gap * (columns - 1))) / columns;
                  final cards = <Widget?>[
                    _metric(context, context.tr('dashboard.openRequests'), '${data.shipmentsOpen}', Icons.local_shipping_outlined, IconTone.teal, '/shipments', AppPermissions.shipmentsView, session),
                    _metric(context, context.tr('dashboard.pendingQuotations'), '${data.quotationsPending}', Icons.request_quote_outlined, IconTone.info, '/quotations', AppPermissions.quotationsView, session),
                    _metric(context, context.tr('dashboard.activeJobs'), '${data.jobsActive}', Icons.work_outline_rounded, IconTone.warning, '/jobs', AppPermissions.jobsView, session),
                    _metric(context, context.tr('dashboard.activeTrips'), '${data.tripsActive}', Icons.route_outlined, IconTone.success, '/trips', AppPermissions.tripsView, session),
                    _metric(context, context.tr('dashboard.inTransit'), '${data.tripsInTransit}', Icons.moving, IconTone.teal, '/trips', AppPermissions.tripsView, session),
                    _metric(context, context.tr('dashboard.available'), Formatters.money(data.walletAvailable, locale: locale), Icons.account_balance_wallet_outlined, IconTone.coral, '/finance', AppPermissions.walletsView, session),
                    _metric(context, context.tr('dashboard.pendingWallet'), Formatters.money(data.walletPending, locale: locale), Icons.hourglass_bottom_outlined, IconTone.warning, '/finance', AppPermissions.walletsView, session),
                    _metric(context, context.tr('dashboard.commission'), Formatters.money(data.commissionAmount, locale: locale), Icons.account_balance_outlined, IconTone.success, '/finance', AppPermissions.paymentsView, session),
                    _metric(context, context.tr('dashboard.invoices'), '${data.invoicesCount}', Icons.receipt_long_outlined, IconTone.info, '/finance', AppPermissions.invoicesView, session),
                  ].whereType<Widget>().toList();
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards)
                        SizedBox(width: itemWidth, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('app.companyFleetNote'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (session.permissions.can(AppPermissions.jobsView))
                SectionCard(
                  title: context.tr('dashboard.recentJobs'),
                  icon: Icons.work_outline_rounded,
                  tone: IconTone.warning,
                  child: const _DashboardJobs(),
                ),
              const SizedBox(height: 12),
              if (session.permissions.can(AppPermissions.tripsAssign))
                SectionCard(
                  title: context.tr('dashboard.unassignedTrips'),
                  icon: Icons.assignment_ind_outlined,
                  tone: IconTone.coral,
                  child: const _DashboardUnassigned(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    IconTone tone,
    String path,
    String permission,
    SessionState session,
  ) {
    if (!session.permissions.can(permission)) {
      return null;
    }
    return MetricCard(
      label: label,
      value: value,
      icon: icon,
      tone: tone,
      onTap: () => context.go(path),
    );
  }
}

class _DashboardJobs extends ConsumerWidget {
  const _DashboardJobs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
    return AsyncBody(
      value: jobs,
      onRetry: () => ref.invalidate(jobsProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('jobs.empty'), icon: Icons.work_outline_rounded),
      builder: (data) {
        final items = data.items.take(4).toList();
        return Column(
          children: [
            for (final job in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconWell(
                  icon: Icons.work_outline_rounded,
                  tone: IconTone.warning,
                  size: IconWellSize.sm,
                ),
                title: Text(job.reference ?? ''),
                subtitle: Text(job.customer?.name ?? context.tr('common.customer')),
                trailing: Text(Formatters.percent(job.progressPercent)),
                onTap: () => context.go('/jobs/${job.id}'),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardUnassigned extends ConsumerWidget {
  const _DashboardUnassigned();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(unassignedTripsProvider);
    return AsyncBody(
      value: trips,
      onRetry: () => ref.invalidate(unassignedTripsProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('dispatch.empty'), icon: Icons.assignment_ind_outlined),
      builder: (data) {
        return Column(
          children: [
            for (final trip in data.items.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const IconWell(
                  icon: Icons.route_outlined,
                  tone: IconTone.coral,
                  size: IconWellSize.sm,
                ),
                title: Text(trip.reference ?? ''),
                subtitle: Text('${trip.pickupCity ?? ''} → ${trip.deliveryCity ?? ''}'),
                onTap: () => context.go('/dispatch'),
              ),
          ],
        );
      },
    );
  }
}
