import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/paginated.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/settlement.dart';
import '../../../shared/models/wallet.dart';
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

final walletProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(financeRepositoryProvider).wallet();
});

final walletLedgerProvider = FutureProvider.autoDispose((ref) async {
  final wallet = await ref.watch(walletProvider.future);
  if (wallet == null) {
    return const Paginated<WalletTransaction>(items: [], currentPage: 1, lastPage: 1, perPage: 15, total: 0);
  }
  return ref.watch(financeRepositoryProvider).walletTransactions(wallet.id);
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
    _tabs = TabController(length: 4, vsync: this);
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
      AppPermissions.walletsView,
    ]);
    if (!canAny) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(title: context.tr('finance.title'), subtitle: context.tr('finance.subtitle')),
          if (permissions.can(AppPermissions.walletsView)) ...[
            const SizedBox(height: 16),
            const _WalletHeader(),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.navy,
              indicatorColor: AppColors.amber,
              tabs: [
                Tab(text: context.tr('finance.ledger')),
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
                permissions.can(AppPermissions.walletsView) ? const _LedgerTab() : const NoPermissionState(),
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

class _WalletHeader extends ConsumerWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return AsyncBody(
      value: ref.watch(walletProvider),
      onRetry: () => ref.invalidate(walletProvider),
      builder: (wallet) {
        final currency = wallet?.currency;
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 5
                : constraints.maxWidth >= 720
                    ? 3
                    : 2;
            final itemWidth = (constraints.maxWidth - (12 * (columns - 1))) / columns;
            final cards = [
              (context.tr('finance.available'), wallet?.availableBalance ?? 0),
              (context.tr('finance.pending'), wallet?.pendingBalance ?? 0),
              (context.tr('finance.reserved'), wallet?.reservedBalance ?? 0),
              (context.tr('finance.lifetimeEarned'), wallet?.lifetimeEarned ?? 0),
              (context.tr('finance.lifetimeWithdrawn'), wallet?.lifetimeWithdrawn ?? 0),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      label: card.$1,
                      value: Formatters.money(card.$2, currency: currency, locale: locale),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LedgerTab extends ConsumerWidget {
  const _LedgerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return AsyncBody(
      value: ref.watch(walletLedgerProvider),
      onRetry: () => ref.invalidate(walletLedgerProvider),
      isEmpty: (data) => data.isEmpty,
      empty: EmptyState(message: context.tr('finance.emptyLedger')),
      builder: (data) {
        return ListView(
          children: [
            ResponsiveDataView<WalletTransaction>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('common.type')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('nav.jobs')),
                DataColumnSpec(context.tr('finance.payments')),
                DataColumnSpec(context.tr('common.createdAt')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                StatusBadge(status: item.type),
                Text(Formatters.money(item.amount, currency: item.currency, locale: locale)),
                Text(item.jobReference ?? '—'),
                Text(item.paymentReference ?? '—'),
                Text(Formatters.dateTime(item.createdAt, locale: locale)),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(
                    [
                      item.jobReference,
                      Formatters.money(item.amount, currency: item.currency, locale: locale),
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: StatusBadge(status: item.type),
                ),
              ),
            ),
          ],
        );
      },
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
