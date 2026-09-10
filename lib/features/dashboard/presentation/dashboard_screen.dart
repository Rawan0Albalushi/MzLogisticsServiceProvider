import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/dashboard.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
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
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
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
              if (session.isPendingReview) ...[
                const SizedBox(height: 16),
                const PendingReviewBanner(),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1400
                      ? 4
                      : width >= 900
                      ? 3
                      : 2;
                  final itemWidth = (width - (12 * (columns - 1))) / columns;
                  final cards = <Widget?>[
                    _metric(context, context.tr('dashboard.openRequests'), '${data.shipmentsOpen}', Icons.local_shipping_outlined, '/shipments', AppPermissions.shipmentsView, session),
                    _metric(context, context.tr('dashboard.pendingQuotations'), '${data.quotationsPending}', Icons.request_quote_outlined, '/quotations', AppPermissions.quotationsView, session),
                    _metric(context, context.tr('dashboard.activeJobs'), '${data.jobsActive}', Icons.work_outline, '/jobs', AppPermissions.jobsView, session),
                    _metric(context, context.tr('dashboard.activeTrips'), '${data.tripsActive}', Icons.route_outlined, '/trips', AppPermissions.tripsView, session),
                    _metric(context, context.tr('dashboard.inTransit'), '${data.tripsInTransit}', Icons.moving, '/trips', AppPermissions.tripsView, session),
                    _metric(context, context.tr('dashboard.receivable'), Formatters.money(data.providerReceivable, locale: locale), Icons.payments_outlined, '/finance', AppPermissions.paymentsView, session),
                    _metric(context, context.tr('dashboard.commission'), Formatters.money(data.commissionAmount, locale: locale), Icons.account_balance_outlined, '/finance', AppPermissions.paymentsView, session),
                    _metric(context, context.tr('dashboard.invoices'), '${data.invoicesCount}', Icons.receipt_long_outlined, '/finance', AppPermissions.invoicesView, session),
                  ].whereType<Widget>().toList();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final card in cards)
                        SizedBox(width: itemWidth, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(context.tr('app.companyFleetNote'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (session.permissions.can(AppPermissions.jobsView))
                SectionCard(
                  title: context.tr('dashboard.recentJobs'),
                  child: const _DashboardJobs(),
                ),
              const SizedBox(height: 12),
              if (session.permissions.can(AppPermissions.tripsAssign))
                SectionCard(
                  title: context.tr('dashboard.unassignedTrips'),
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
      empty: EmptyState(message: context.tr('jobs.empty')),
      builder: (data) {
        final items = data.items.take(4).toList();
        return Column(
          children: [
            for (final job in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
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
      empty: EmptyState(message: context.tr('dispatch.empty')),
      builder: (data) {
        return Column(
          children: [
            for (final trip in data.items.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
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
