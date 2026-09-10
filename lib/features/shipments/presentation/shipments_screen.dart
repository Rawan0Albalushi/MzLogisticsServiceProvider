import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/shipment.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final shipmentSearchProvider = StateProvider<String>((ref) => '');
final shipmentPageProvider = StateProvider<int>((ref) => 1);

final shipmentsProvider = FutureProvider.autoDispose((ref) {
  final search = ref.watch(shipmentSearchProvider);
  final page = ref.watch(shipmentPageProvider);
  return ref.watch(shipmentRepositoryProvider).list(page: page, search: search);
});

class ShipmentsScreen extends ConsumerWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.shipmentsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    final orgId = session.user?.organizationId;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: context.tr('shipments.title'),
            subtitle: context.tr('shipments.subtitle'),
            trailing: SizedBox(
              width: 260,
              child: TextField(
                decoration: InputDecoration(hintText: context.tr('common.search'), prefixIcon: const Icon(Icons.search)),
                onChanged: (value) {
                  ref.read(shipmentSearchProvider.notifier).state = value;
                  ref.read(shipmentPageProvider.notifier).state = 1;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(shipmentsProvider),
              onRetry: () => ref.invalidate(shipmentsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('shipments.empty'), icon: Icons.local_shipping_outlined),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<Shipment>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('common.reference')),
                        DataColumnSpec(context.tr('shipments.cargo')),
                        DataColumnSpec(context.tr('shipments.pickup')),
                        DataColumnSpec(context.tr('shipments.delivery')),
                        DataColumnSpec(context.tr('common.quantity')),
                        DataColumnSpec(context.tr('common.status')),
                        DataColumnSpec(context.tr('common.actions')),
                      ],
                      onRowTap: (item) => context.go('/shipments/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.cargoType ?? ''),
                        Text(item.pickupCity ?? ''),
                        Text(item.deliveryCity ?? ''),
                        Text('${Formatters.number(item.quantity, locale: locale)} ${item.quantityUnit ?? ''}'),
                        StatusBadge(status: item.status),
                        _quoteAction(context, session, item, orgId),
                      ],
                      cardBuilder: (item) => Card(
                        child: InkWell(
                          onTap: () => context.go('/shipments/${item.id}'),
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
                                const SizedBox(height: 8),
                                Text('${item.pickupCity ?? ''} → ${item.deliveryCity ?? ''}'),
                                Text('${item.cargoType ?? ''} · ${Formatters.number(item.weightTons, locale: locale)} ${context.tr('common.tons')}'),
                                const SizedBox(height: 10),
                                _quoteAction(context, session, item, orgId),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(shipmentPageProvider.notifier).state = page,
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

  Widget _quoteAction(BuildContext context, SessionState session, Shipment item, int? orgId) {
    if (!session.permissions.can(AppPermissions.quotationsCreate)) {
      return const SizedBox.shrink();
    }
    if (item.quotedBy(orgId)) {
      return Text(context.tr('shipments.alreadyQuoted'), style: Theme.of(context).textTheme.bodySmall);
    }
    return TextButton(
      onPressed: () => context.go('/shipments/${item.id}/quote'),
      child: Text(context.tr('shipments.quote')),
    );
  }
}
