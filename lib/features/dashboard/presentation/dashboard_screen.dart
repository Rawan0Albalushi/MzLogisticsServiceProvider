import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/dashboard.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/account_restricted_view.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/dashboard_kpi.dart';
import 'widgets/dashboard_queues.dart';

final dashboardUpdatedAtProvider = StateProvider<DateTime?>((ref) => null);

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
    ref.listen(dashboardProvider, (_, next) {
      if (next.hasValue) {
        ref.read(dashboardUpdatedAtProvider.notifier).state = DateTime.now();
      }
    });

    final locale = Localizations.localeOf(context).languageCode;
    final canShipments = session.permissions.can(AppPermissions.shipmentsView);
    final canJobs = session.permissions.can(AppPermissions.jobsView);
    final canTrips = session.permissions.can(AppPermissions.tripsView);
    final updated = ref.watch(dashboardUpdatedAtProvider);

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () =>
          _reload(ref, shipments: canShipments, jobs: canJobs, trips: canTrips),
      child: AppPage(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AsyncBody(
          value: ref.watch(dashboardProvider),
          skipLoadingOnReload: true,
          onRetry: () => ref.invalidate(dashboardProvider),
          builder: (data) {
            final attention = _attention(context, data, session, locale);
            final operations = _operations(context, data, session, locale);
            final finance = _finance(context, data, session, locale);
            final links = _links(context, session);
            final updatedLabel = updated == null
                ? null
                : context.tr('dashboard.updatedAt', {
                    'time': Formatters.dateTime(
                      updated.toIso8601String(),
                      locale: locale,
                    ),
                  });
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: context.tr(_greetingKey(), {
                    'name': _firstName(context, session),
                  }),
                  subtitle: context.tr('dashboard.subtitle'),
                  actions: [
                    if (updatedLabel != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          updatedLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted, height: 1.4),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _reload(
                          ref,
                          shipments: canShipments,
                          jobs: canJobs,
                          trips: canTrips,
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(context.tr('common.refresh')),
                    ),
                  ],
                ),
                if (attention.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DashboardSection(
                    title: context.tr('dashboard.attention'),
                    child: DashboardAttentionList(items: attention),
                  ),
                ],
                if (operations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DashboardSection(
                    title: context.tr('dashboard.operations'),
                    child: DashboardKpiGrid(metrics: operations),
                  ),
                ],
                if (canShipments || canJobs || canTrips) ...[
                  const SizedBox(height: 24),
                  DashboardQueueGrid(
                    showShipments: canShipments,
                    showJobs: canJobs,
                    showTrips: canTrips,
                  ),
                ],
                if (finance.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DashboardSection(
                    title: context.tr('dashboard.finance'),
                    child: DashboardKpiGrid(metrics: finance),
                  ),
                ],
                if (links.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DashboardSection(
                    title: context.tr('dashboard.quickLinks'),
                    child: DashboardQuickLinkGrid(links: links),
                  ),
                ],
                const SizedBox(height: 20),
                const _FleetNote(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _reload(
    WidgetRef ref, {
    required bool shipments,
    required bool jobs,
    required bool trips,
  }) async {
    ref.invalidate(dashboardProvider);
    final tasks = <Future<void>>[
      ref.read(dashboardProvider.future).then((_) {}),
    ];
    if (shipments) {
      ref.invalidate(dashboardOpenShipmentsProvider);
      tasks.add(ref.read(dashboardOpenShipmentsProvider.future).then((_) {}));
    }
    if (jobs) {
      ref.invalidate(dashboardActiveJobsProvider);
      tasks.add(ref.read(dashboardActiveJobsProvider.future).then((_) {}));
    }
    if (trips) {
      ref.invalidate(dashboardTransitTripsProvider);
      tasks.add(ref.read(dashboardTransitTripsProvider.future).then((_) {}));
    }
    await Future.wait(tasks);
  }

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'dashboard.greetingMorning';
    }
    if (hour < 17) {
      return 'dashboard.greetingAfternoon';
    }
    return 'dashboard.greetingEvening';
  }

  String _firstName(BuildContext context, SessionState session) {
    final name = session.user?.name?.trim();
    if (name == null || name.isEmpty) {
      return context.tr('app.name');
    }
    return name.split(RegExp(r'\s+')).first;
  }

  List<DashboardAttentionItem> _attention(
    BuildContext context,
    DashboardSnapshot data,
    SessionState session,
    String locale,
  ) {
    String count(num value) =>
        Formatters.number(value, locale: locale, decimals: 0);
    final view = context.tr('dashboard.viewAll');
    final can = session.permissions.can;
    return [
      if (can(AppPermissions.quotationsView) && data.quotationsPending > 0)
        DashboardAttentionItem(
          label: context.tr('dashboard.pendingQuotations'),
          count: count(data.quotationsPending),
          icon: Icons.request_quote_outlined,
          tone: DashboardKpiTone.warning,
          viewLabel: view,
          onTap: () => context.go('/quotations'),
        ),
      if (can(AppPermissions.jobsView) && data.jobsPendingDispatch > 0)
        DashboardAttentionItem(
          label: context.tr('dashboard.jobsPendingDispatch'),
          count: count(data.jobsPendingDispatch),
          icon: Icons.work_outline_rounded,
          tone: DashboardKpiTone.warning,
          viewLabel: view,
          onTap: () => context.go('/jobs'),
        ),
      if (can(AppPermissions.tripsView) && data.tripsUnassigned > 0)
        DashboardAttentionItem(
          label: context.tr('dashboard.tripsUnassigned'),
          count: count(data.tripsUnassigned),
          icon: Icons.route_outlined,
          tone: DashboardKpiTone.danger,
          viewLabel: view,
          onTap: () => context.go(
            can(AppPermissions.tripsAssign) ? '/dispatch' : '/trips',
          ),
        ),
      if (can(AppPermissions.paymentsView) && data.paymentsPending > 0)
        DashboardAttentionItem(
          label: context.tr('dashboard.paymentsPending'),
          count: count(data.paymentsPending),
          icon: Icons.payments_outlined,
          tone: DashboardKpiTone.warning,
          viewLabel: view,
          onTap: () => context.go('/finance'),
        ),
      if (can(AppPermissions.settlementsView) && data.settlementsPending > 0)
        DashboardAttentionItem(
          label: context.tr('dashboard.settlementsPending'),
          count: count(data.settlementsPending),
          icon: Icons.account_balance_outlined,
          tone: DashboardKpiTone.info,
          viewLabel: view,
          onTap: () => context.go('/finance'),
        ),
    ];
  }

  List<DashboardKpi> _operations(
    BuildContext context,
    DashboardSnapshot data,
    SessionState session,
    String locale,
  ) {
    String count(num value) =>
        Formatters.number(value, locale: locale, decimals: 0);
    final can = session.permissions.can;
    return [
      if (can(AppPermissions.shipmentsView))
        DashboardKpi(
          label: context.tr('dashboard.openRequests'),
          value: count(data.shipmentsOpen),
          hint: context.tr('dashboard.shipmentsOpenHint'),
          icon: Icons.local_shipping_outlined,
          tone: data.shipmentsOpen > 0
              ? DashboardKpiTone.info
              : DashboardKpiTone.neutral,
          onTap: () => context.go('/shipments'),
        ),
      if (can(AppPermissions.quotationsView))
        DashboardKpi(
          label: context.tr('dashboard.pendingQuotations'),
          value: count(data.quotationsPending),
          hint: context.tr('dashboard.quotationsPendingHint'),
          icon: Icons.request_quote_outlined,
          tone: data.quotationsPending > 0
              ? DashboardKpiTone.warning
              : DashboardKpiTone.neutral,
          onTap: () => context.go('/quotations'),
        ),
      if (can(AppPermissions.jobsView))
        DashboardKpi(
          label: context.tr('dashboard.activeJobs'),
          value: count(data.jobsActive),
          hint: context.tr('dashboard.jobsActiveHint'),
          icon: Icons.work_outline_rounded,
          tone: data.jobsPendingDispatch > 0
              ? DashboardKpiTone.warning
              : DashboardKpiTone.info,
          onTap: () => context.go('/jobs'),
        ),
      if (can(AppPermissions.tripsView))
        DashboardKpi(
          label: context.tr('dashboard.inTransit'),
          value: count(data.tripsInTransit),
          hint: context.tr('dashboard.tripsInTransitHint'),
          icon: Icons.route_outlined,
          tone: data.tripsInTransit > 0
              ? DashboardKpiTone.info
              : DashboardKpiTone.neutral,
          onTap: () => context.go('/trips'),
        ),
    ];
  }

  List<DashboardKpi> _finance(
    BuildContext context,
    DashboardSnapshot data,
    SessionState session,
    String locale,
  ) {
    String money(num value) => Formatters.money(value, locale: locale);
    String count(num value) =>
        Formatters.number(value, locale: locale, decimals: 0);
    final can = session.permissions.can;
    return [
      if (can(AppPermissions.paymentsView))
        DashboardKpi(
          label: context.tr('dashboard.paymentsCompleted'),
          value: money(data.paymentsCompletedAmount),
          hint: context.tr('dashboard.paymentsCompletedHint'),
          icon: Icons.payments_outlined,
          tone: DashboardKpiTone.success,
          onTap: () => context.go('/finance'),
        ),
      if (can(AppPermissions.paymentsView))
        DashboardKpi(
          label: context.tr('dashboard.commission'),
          value: money(data.commissionAmount),
          hint: context.tr('dashboard.commissionHint'),
          icon: Icons.account_balance_outlined,
          onTap: () => context.go('/finance'),
        ),
      if (can(AppPermissions.walletsView))
        DashboardKpi(
          label: context.tr('dashboard.receivable'),
          value: money(data.providerReceivable),
          hint: context.tr('dashboard.receivableHint'),
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => context.go('/finance'),
        ),
      if (can(AppPermissions.walletsView))
        DashboardKpi(
          label: context.tr('dashboard.available'),
          value: money(data.walletAvailable),
          hint: context.tr('dashboard.availableHint'),
          icon: Icons.savings_outlined,
          tone: data.walletAvailable > 0
              ? DashboardKpiTone.success
              : DashboardKpiTone.neutral,
          onTap: () => context.go('/finance'),
        ),
      if (can(AppPermissions.invoicesView))
        DashboardKpi(
          label: context.tr('dashboard.invoicesUnpaid'),
          value: count(data.invoicesUnpaid),
          hint: context.tr('dashboard.invoicesUnpaidHint'),
          icon: Icons.receipt_long_outlined,
          tone: data.invoicesUnpaid > 0
              ? DashboardKpiTone.warning
              : DashboardKpiTone.neutral,
          onTap: () => context.go('/finance'),
        ),
    ];
  }

  List<DashboardQuickLink> _links(BuildContext context, SessionState session) {
    final can = session.permissions.can;
    final finance =
        can(AppPermissions.paymentsView) ||
        can(AppPermissions.invoicesView) ||
        can(AppPermissions.settlementsView) ||
        can(AppPermissions.walletsView);
    return [
      if (can(AppPermissions.shipmentsView))
        DashboardQuickLink(
          title: context.tr('dashboard.shortcutShipments'),
          hint: context.tr('dashboard.shortcutShipmentsHint'),
          icon: Icons.local_shipping_outlined,
          tone: IconTone.teal,
          onTap: () => context.go('/shipments'),
        ),
      if (can(AppPermissions.tripsAssign))
        DashboardQuickLink(
          title: context.tr('dashboard.shortcutDispatch'),
          hint: context.tr('dashboard.shortcutDispatchHint'),
          icon: Icons.assignment_ind_outlined,
          tone: IconTone.warning,
          onTap: () => context.go('/dispatch'),
        ),
      if (can(AppPermissions.tripsView))
        DashboardQuickLink(
          title: context.tr('dashboard.shortcutTrips'),
          hint: context.tr('dashboard.shortcutTripsHint'),
          icon: Icons.route_outlined,
          tone: IconTone.success,
          onTap: () => context.go('/trips'),
        ),
      if (finance)
        DashboardQuickLink(
          title: context.tr('dashboard.shortcutFinance'),
          hint: context.tr('dashboard.shortcutFinanceHint'),
          icon: Icons.account_balance_outlined,
          tone: IconTone.info,
          onTap: () => context.go('/finance'),
        ),
    ];
  }
}

class _FleetNote extends StatelessWidget {
  const _FleetNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 16, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr('app.companyFleetNote'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.muted, height: 1.45),
          ),
        ),
      ],
    );
  }
}
