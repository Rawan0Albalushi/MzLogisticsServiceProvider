import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/settlement.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final paymentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(financeRepositoryProvider).payments();
});

final invoicesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(financeRepositoryProvider).invoices();
});

final settlementsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(financeRepositoryProvider).settlements();
});

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(sessionProvider).permissions;
    final canAny = permissions.any([
      AppPermissions.paymentsView,
      AppPermissions.invoicesView,
      AppPermissions.settlementsView,
    ]);
    if (!canAny) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(title: context.tr('finance.title')),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.navy,
              indicatorColor: AppColors.amber,
              tabs: [
                Tab(text: context.tr('finance.payments')),
                Tab(text: context.tr('finance.invoices')),
                Tab(text: context.tr('finance.settlements')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                permissions.can(AppPermissions.paymentsView) ? const _PaymentsTab() : const NoPermissionState(),
                permissions.can(AppPermissions.invoicesView) ? const _InvoicesTab() : const NoPermissionState(),
                permissions.can(AppPermissions.settlementsView) ? const _SettlementsTab() : const NoPermissionState(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return AsyncBody(
      value: ref.watch(paymentsProvider),
      onRetry: () => ref.invalidate(paymentsProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('finance.emptyPayments')),
      builder: (data) {
        return ListView(
          children: [
            ResponsiveDataView<Payment>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('finance.providerAmount')),
                DataColumnSpec(context.tr('finance.commission')),
                DataColumnSpec(context.tr('finance.method')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(Formatters.money(item.amount, currency: item.currency, locale: locale)),
                Text(Formatters.money(item.providerAmount, currency: item.currency, locale: locale)),
                Text(Formatters.money(item.commissionAmount, currency: item.currency, locale: locale)),
                Text(item.method ?? '—'),
                StatusBadge(status: item.status),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(Formatters.money(item.providerAmount, currency: item.currency, locale: locale)),
                  trailing: StatusBadge(status: item.status),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return AsyncBody(
      value: ref.watch(invoicesProvider),
      onRetry: () => ref.invalidate(invoicesProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('finance.emptyInvoices')),
      builder: (data) {
        return ListView(
          children: [
            ResponsiveDataView<Invoice>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('common.type')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('finance.issued')),
                DataColumnSpec(context.tr('finance.due')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(item.type ?? ''),
                Text(Formatters.money(item.amount, currency: item.currency, locale: locale)),
                Text(Formatters.date(item.issuedAt, locale: locale)),
                Text(Formatters.date(item.dueAt, locale: locale)),
                StatusBadge(status: item.status),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(Formatters.money(item.amount, currency: item.currency, locale: locale)),
                  trailing: StatusBadge(status: item.status),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettlementsTab extends ConsumerWidget {
  const _SettlementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return AsyncBody(
      value: ref.watch(settlementsProvider),
      onRetry: () => ref.invalidate(settlementsProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('finance.emptySettlements')),
      builder: (data) {
        return ListView(
          children: [
            ResponsiveDataView<Settlement>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('finance.net')),
                DataColumnSpec(context.tr('finance.period')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(Formatters.money(item.amount, currency: item.currency, locale: locale)),
                Text(Formatters.money(item.netAmount, currency: item.currency, locale: locale)),
                Text('${Formatters.date(item.periodStart, locale: locale)} – ${Formatters.date(item.periodEnd, locale: locale)}'),
                StatusBadge(status: item.status),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(
                    '${Formatters.money(item.netAmount, currency: item.currency, locale: locale)} · ${Formatters.date(item.periodStart, locale: locale)}',
                  ),
                  trailing: StatusBadge(status: item.status),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
