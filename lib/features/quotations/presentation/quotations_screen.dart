import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final quotationStatusProvider = StateProvider<String?>((ref) => null);
final quotationPageProvider = StateProvider<int>((ref) => 1);

final quotationsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(quotationRepositoryProvider).list(
        page: ref.watch(quotationPageProvider),
        status: ref.watch(quotationStatusProvider),
      );
});

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.quotationsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: context.tr('quotations.title'),
            subtitle: context.tr('quotations.subtitle'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChips(
              options: const ['submitted', 'withdrawn', 'accepted', 'rejected', 'expired'],
              selected: ref.watch(quotationStatusProvider),
              onSelected: (value) {
                ref.read(quotationStatusProvider.notifier).state = value;
                ref.read(quotationPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(quotationsProvider),
              onRetry: () => ref.invalidate(quotationsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('quotations.empty')),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<Quotation>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('common.reference')),
                        DataColumnSpec(context.tr('nav.shipments')),
                        DataColumnSpec(context.tr('quotations.totalPrice')),
                        DataColumnSpec(context.tr('quotations.truckType')),
                        DataColumnSpec(context.tr('common.status')),
                        DataColumnSpec(context.tr('common.actions')),
                      ],
                      onRowTap: (item) => context.go('/quotations/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.shipment?.reference ?? ''),
                        Text(Formatters.money(item.totalPrice, currency: item.currency, locale: locale)),
                        Text(context.l10n.truckType(item.truckType, label: item.truckTypeLabel)),
                        StatusBadge(status: item.status),
                        _WithdrawButton(quotation: item),
                      ],
                      cardBuilder: (item) => Card(
                        child: InkWell(
                          onTap: () => context.go('/quotations/${item.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item.reference ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    StatusBadge(status: item.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(Formatters.money(item.totalPrice, currency: item.currency, locale: locale)),
                                Text('${item.truckCount ?? 0} ${context.tr('common.trucks')} · ${item.tripCount ?? 0} ${context.tr('common.trips')}'),
                                _WithdrawButton(quotation: item),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(quotationPageProvider.notifier).state = page,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawButton extends ConsumerWidget {
  const _WithdrawButton({required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final can = ref.watch(sessionProvider).permissions.can(AppPermissions.quotationsManage);
    if (!can || !quotation.canWithdraw) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () async {
        final ok = await showConfirmDialog(context, message: context.tr('quotations.withdrawConfirm'));
        if (!ok) {
          return;
        }
        try {
          await ref.read(quotationRepositoryProvider).withdraw(quotation.id);
          ref.invalidate(quotationsProvider);
        } on ApiException catch (error) {
          if (context.mounted) {
            showAppSnack(context, error.message);
          }
        }
      },
      child: Text(context.tr('common.withdraw')),
    );
  }
}
