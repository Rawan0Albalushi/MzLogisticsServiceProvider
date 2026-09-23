import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/paginated.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/settlement.dart';
import '../../../shared/models/wallet.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
import 'request_withdrawal_dialog.dart';

final paymentStatusProvider = StateProvider<String?>((ref) => null);
final paymentMethodProvider = StateProvider<String?>((ref) => null);
final paymentSearchProvider = StateProvider<String>((ref) => '');
final paymentDateFromProvider = StateProvider<String?>((ref) => null);
final paymentDateToProvider = StateProvider<String?>((ref) => null);
final paymentPageProvider = StateProvider<int>((ref) => 1);
final invoiceStatusProvider = StateProvider<String?>((ref) => null);
final invoiceTypeProvider = StateProvider<String?>((ref) => null);
final invoiceSearchProvider = StateProvider<String>((ref) => '');
final invoiceDateFromProvider = StateProvider<String?>((ref) => null);
final invoiceDateToProvider = StateProvider<String?>((ref) => null);
final invoicePageProvider = StateProvider<int>((ref) => 1);
final settlementStatusProvider = StateProvider<String?>((ref) => null);
final settlementSearchProvider = StateProvider<String>((ref) => '');
final settlementDateFromProvider = StateProvider<String?>((ref) => null);
final settlementDateToProvider = StateProvider<String?>((ref) => null);
final settlementPageProvider = StateProvider<int>((ref) => 1);
final ledgerTypeProvider = StateProvider<String?>((ref) => null);
final ledgerSearchProvider = StateProvider<String>((ref) => '');
final ledgerDateFromProvider = StateProvider<String?>((ref) => null);
final ledgerDateToProvider = StateProvider<String?>((ref) => null);
final ledgerPageProvider = StateProvider<int>((ref) => 1);

final paymentsProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(financeRepositoryProvider)
      .payments(
        page: ref.watch(paymentPageProvider),
        status: ref.watch(paymentStatusProvider),
        method: ref.watch(paymentMethodProvider),
        search: ref.watch(paymentSearchProvider),
        dateFrom: ref.watch(paymentDateFromProvider),
        dateTo: ref.watch(paymentDateToProvider),
      );
});

final invoicesProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(financeRepositoryProvider)
      .invoices(
        page: ref.watch(invoicePageProvider),
        status: ref.watch(invoiceStatusProvider),
        type: ref.watch(invoiceTypeProvider),
        search: ref.watch(invoiceSearchProvider),
        dateFrom: ref.watch(invoiceDateFromProvider),
        dateTo: ref.watch(invoiceDateToProvider),
      );
});

final settlementsProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(financeRepositoryProvider)
      .settlements(
        page: ref.watch(settlementPageProvider),
        status: ref.watch(settlementStatusProvider),
        search: ref.watch(settlementSearchProvider),
        dateFrom: ref.watch(settlementDateFromProvider),
        dateTo: ref.watch(settlementDateToProvider),
      );
});

final walletProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(financeRepositoryProvider).wallet();
});

final walletLedgerProvider = FutureProvider.autoDispose((ref) async {
  final wallet = await ref.watch(walletProvider.future);
  if (wallet == null) {
    return const Paginated<WalletTransaction>(
      items: [],
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: 0,
    );
  }
  return ref
      .watch(financeRepositoryProvider)
      .walletTransactions(
        wallet.id,
        page: ref.watch(ledgerPageProvider),
        type: ref.watch(ledgerTypeProvider),
        search: ref.watch(ledgerSearchProvider),
        dateFrom: ref.watch(ledgerDateFromProvider),
        dateTo: ref.watch(ledgerDateToProvider),
      );
});

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging || !mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _requestWithdrawal() async {
    final Wallet? wallet;
    try {
      wallet = await ref.read(walletProvider.future);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, context.tr('common.error'));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (wallet == null) {
      showAppSnack(context, context.tr('finance.withdrawNoneAvailable'));
      return;
    }
    final settlement = await showRequestWithdrawalDialog(
      context,
      wallet: wallet,
    );
    if (!mounted || settlement == null) {
      return;
    }
    ref.invalidate(walletProvider);
    ref.invalidate(walletLedgerProvider);
    ref.invalidate(settlementsProvider);
    showAppSnack(context, context.tr('finance.withdrawSuccess'));
    if (ref
        .read(sessionProvider)
        .permissions
        .can(AppPermissions.settlementsView)) {
      _tabs.animateTo(3);
    }
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
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('finance.title'),
            subtitle: context.tr('finance.subtitle'),
            actions: [
              if (permissions.can(AppPermissions.settlementsRequest))
                AppButton(
                  label: context.tr('finance.withdraw'),
                  icon: Icons.south_west_rounded,
                  onPressed: _requestWithdrawal,
                ),
            ],
          ),
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
              tabs: [
                Tab(text: context.tr('finance.ledger')),
                Tab(text: context.tr('finance.payments')),
                Tab(text: context.tr('finance.invoices')),
                Tab(text: context.tr('finance.settlements')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          switch (_tabs.index) {
            0 =>
              permissions.can(AppPermissions.walletsView)
                  ? const _LedgerTab()
                  : const NoPermissionState(),
            1 =>
              permissions.can(AppPermissions.paymentsView)
                  ? const _PaymentsTab()
                  : const NoPermissionState(),
            2 =>
              permissions.can(AppPermissions.invoicesView)
                  ? const _InvoicesTab()
                  : const NoPermissionState(),
            _ =>
              permissions.can(AppPermissions.settlementsView)
                  ? const _SettlementsTab()
                  : const NoPermissionState(),
          },
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
                : constraints.maxWidth >= 420
                ? 2
                : 1;
            final itemWidth =
                (constraints.maxWidth - (12 * (columns - 1))) / columns;
            final cards = [
              (
                context.tr('finance.available'),
                wallet?.availableBalance ?? 0,
                Icons.account_balance_wallet_outlined,
                IconTone.success,
              ),
              (
                context.tr('finance.pending'),
                wallet?.pendingBalance ?? 0,
                Icons.hourglass_bottom_outlined,
                IconTone.warning,
              ),
              (
                context.tr('finance.reserved'),
                wallet?.reservedBalance ?? 0,
                Icons.lock_outline,
                IconTone.coral,
              ),
              (
                context.tr('finance.lifetimeEarned'),
                wallet?.lifetimeEarned ?? 0,
                Icons.trending_up_rounded,
                IconTone.teal,
              ),
              (
                context.tr('finance.lifetimeWithdrawn'),
                wallet?.lifetimeWithdrawn ?? 0,
                Icons.south_west_rounded,
                IconTone.info,
              ),
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
                      value: Formatters.money(
                        card.$2,
                        currency: currency,
                        locale: locale,
                      ),
                      icon: card.$3,
                      tone: card.$4,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          children: [
            FilterSearchField(
              hint: context.tr('common.searchReference'),
              onChanged: (value) {
                ref.read(ledgerSearchProvider.notifier).state = value;
                ref.read(ledgerPageProvider.notifier).state = 1;
              },
            ),
            FilterSelect(
              options: AppConfig.walletTransactionTypes,
              value: ref.watch(ledgerTypeProvider),
              onChanged: (value) {
                ref.read(ledgerTypeProvider.notifier).state = value;
                ref.read(ledgerPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
              allLabel: context.tr('common.allTypes'),
            ),
            FilterDateRange(
              from: ref.watch(ledgerDateFromProvider),
              to: ref.watch(ledgerDateToProvider),
              onChanged: (from, to) {
                ref.read(ledgerDateFromProvider.notifier).state = from;
                ref.read(ledgerDateToProvider.notifier).state = to;
                ref.read(ledgerPageProvider.notifier).state = 1;
              },
            ),
          ],
        ),
        AsyncBody(
          value: ref.watch(walletLedgerProvider),
          onRetry: () => ref.invalidate(walletLedgerProvider),
          isEmpty: (data) => data.isEmpty,
          empty: EmptyState(message: context.tr('finance.emptyLedger')),
          builder: (data) {
            return ResponsiveDataView<WalletTransaction>(
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
                Text(
                  Formatters.money(
                    item.amount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
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
                      Formatters.money(
                        item.amount,
                        currency: item.currency,
                        locale: locale,
                      ),
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: StatusBadge(status: item.type),
                ),
              ),
              pagination: TablePagination(
                currentPage: data.currentPage,
                lastPage: data.lastPage,
                total: data.total,
                onPage: (page) =>
                    ref.read(ledgerPageProvider.notifier).state = page,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          children: [
            FilterSearchField(
              hint: context.tr('common.searchReference'),
              onChanged: (value) {
                ref.read(paymentSearchProvider.notifier).state = value;
                ref.read(paymentPageProvider.notifier).state = 1;
              },
            ),
            FilterSelect(
              options: AppConfig.paymentStatuses,
              value: ref.watch(paymentStatusProvider),
              onChanged: (value) {
                ref.read(paymentStatusProvider.notifier).state = value;
                ref.read(paymentPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
            FilterSelect(
              options: AppConfig.paymentMethods,
              value: ref.watch(paymentMethodProvider),
              onChanged: (value) {
                ref.read(paymentMethodProvider.notifier).state = value;
                ref.read(paymentPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
              allLabel: context.tr('common.allMethods'),
            ),
            FilterDateRange(
              from: ref.watch(paymentDateFromProvider),
              to: ref.watch(paymentDateToProvider),
              onChanged: (from, to) {
                ref.read(paymentDateFromProvider.notifier).state = from;
                ref.read(paymentDateToProvider.notifier).state = to;
                ref.read(paymentPageProvider.notifier).state = 1;
              },
            ),
          ],
        ),
        AsyncBody(
          value: ref.watch(paymentsProvider),
          onRetry: () => ref.invalidate(paymentsProvider),
          isEmpty: (data) => data.isEmpty,
          empty: EmptyState(message: context.tr('finance.emptyPayments')),
          builder: (data) {
            return ResponsiveDataView<Payment>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('finance.providerAmount')),
                DataColumnSpec(context.tr('finance.commission')),
                DataColumnSpec(context.tr('finance.method')),
                DataColumnSpec(context.tr('finance.gateway')),
                DataColumnSpec(context.tr('finance.paidAt')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(
                  Formatters.money(
                    item.amount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(
                  Formatters.money(
                    item.providerAmount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(
                  Formatters.money(
                    item.commissionAmount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(item.method ?? '—'),
                Text(item.gateway ?? '—'),
                Text(Formatters.dateTime(item.paidAt, locale: locale)),
                StatusBadge(status: item.status),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(
                    [
                          Formatters.money(
                            item.providerAmount,
                            currency: item.currency,
                            locale: locale,
                          ),
                          item.method,
                          Formatters.dateTime(item.paidAt, locale: locale),
                        ]
                        .where(
                          (value) =>
                              value != null && value.isNotEmpty && value != '—',
                        )
                        .join(' · '),
                  ),
                  trailing: StatusBadge(status: item.status),
                ),
              ),
              pagination: TablePagination(
                currentPage: data.currentPage,
                lastPage: data.lastPage,
                total: data.total,
                onPage: (page) =>
                    ref.read(paymentPageProvider.notifier).state = page,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          children: [
            FilterSearchField(
              hint: context.tr('common.searchReference'),
              onChanged: (value) {
                ref.read(invoiceSearchProvider.notifier).state = value;
                ref.read(invoicePageProvider.notifier).state = 1;
              },
            ),
            FilterSelect(
              options: AppConfig.invoiceTypes,
              value: ref.watch(invoiceTypeProvider),
              onChanged: (value) {
                ref.read(invoiceTypeProvider.notifier).state = value;
                ref.read(invoicePageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
              allLabel: context.tr('common.allTypes'),
            ),
            FilterSelect(
              options: AppConfig.invoiceStatuses,
              value: ref.watch(invoiceStatusProvider),
              onChanged: (value) {
                ref.read(invoiceStatusProvider.notifier).state = value;
                ref.read(invoicePageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
            FilterDateRange(
              from: ref.watch(invoiceDateFromProvider),
              to: ref.watch(invoiceDateToProvider),
              onChanged: (from, to) {
                ref.read(invoiceDateFromProvider.notifier).state = from;
                ref.read(invoiceDateToProvider.notifier).state = to;
                ref.read(invoicePageProvider.notifier).state = 1;
              },
            ),
          ],
        ),
        AsyncBody(
          value: ref.watch(invoicesProvider),
          onRetry: () => ref.invalidate(invoicesProvider),
          isEmpty: (data) => data.isEmpty,
          empty: EmptyState(message: context.tr('finance.emptyInvoices')),
          builder: (data) {
            return ResponsiveDataView<Invoice>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('common.type')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('common.job')),
                DataColumnSpec(context.tr('finance.payments')),
                DataColumnSpec(context.tr('finance.issued')),
                DataColumnSpec(context.tr('finance.due')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(item.type ?? ''),
                Text(
                  Formatters.money(
                    item.amount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(item.job?.reference ?? '—'),
                Text(item.payment?.reference ?? '—'),
                Text(Formatters.date(item.issuedAt, locale: locale)),
                Text(Formatters.date(item.dueAt, locale: locale)),
                StatusBadge(status: item.status),
              ],
              cardBuilder: (item) => Card(
                child: ListTile(
                  title: Text(item.reference ?? ''),
                  subtitle: Text(
                    [
                          Formatters.money(
                            item.amount,
                            currency: item.currency,
                            locale: locale,
                          ),
                          item.job?.reference,
                          Formatters.date(item.dueAt, locale: locale),
                        ]
                        .where(
                          (value) =>
                              value != null && value.toString().isNotEmpty,
                        )
                        .join(' · '),
                  ),
                  trailing: StatusBadge(status: item.status),
                ),
              ),
              pagination: TablePagination(
                currentPage: data.currentPage,
                lastPage: data.lastPage,
                total: data.total,
                onPage: (page) =>
                    ref.read(invoicePageProvider.notifier).state = page,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettlementsTab extends ConsumerWidget {
  const _SettlementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          children: [
            FilterSearchField(
              hint: context.tr('common.searchReference'),
              onChanged: (value) {
                ref.read(settlementSearchProvider.notifier).state = value;
                ref.read(settlementPageProvider.notifier).state = 1;
              },
            ),
            FilterSelect(
              options: AppConfig.settlementStatuses,
              value: ref.watch(settlementStatusProvider),
              onChanged: (value) {
                ref.read(settlementStatusProvider.notifier).state = value;
                ref.read(settlementPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
            FilterDateRange(
              from: ref.watch(settlementDateFromProvider),
              to: ref.watch(settlementDateToProvider),
              onChanged: (from, to) {
                ref.read(settlementDateFromProvider.notifier).state = from;
                ref.read(settlementDateToProvider.notifier).state = to;
                ref.read(settlementPageProvider.notifier).state = 1;
              },
            ),
          ],
        ),
        AsyncBody(
          value: ref.watch(settlementsProvider),
          onRetry: () => ref.invalidate(settlementsProvider),
          isEmpty: (data) => data.isEmpty,
          empty: EmptyState(message: context.tr('finance.emptySettlements')),
          builder: (data) {
            return ResponsiveDataView<Settlement>(
              items: data.items,
              columns: [
                DataColumnSpec(context.tr('common.reference')),
                DataColumnSpec(context.tr('finance.amount')),
                DataColumnSpec(context.tr('finance.commission')),
                DataColumnSpec(context.tr('finance.net')),
                DataColumnSpec(context.tr('finance.period')),
                DataColumnSpec(context.tr('finance.settledAt')),
                DataColumnSpec(context.tr('common.status')),
              ],
              rowCells: (item) => [
                Text(item.reference ?? ''),
                Text(
                  Formatters.money(
                    item.amount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(
                  Formatters.money(
                    item.commissionAmount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(
                  Formatters.money(
                    item.netAmount,
                    currency: item.currency,
                    locale: locale,
                  ),
                ),
                Text(
                  '${Formatters.date(item.periodStart, locale: locale)} – ${Formatters.date(item.periodEnd, locale: locale)}',
                ),
                Text(Formatters.dateTime(item.settledAt, locale: locale)),
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
              pagination: TablePagination(
                currentPage: data.currentPage,
                lastPage: data.lastPage,
                total: data.total,
                onPage: (page) =>
                    ref.read(settlementPageProvider.notifier).state = page,
              ),
            );
          },
        ),
      ],
    );
  }
}
