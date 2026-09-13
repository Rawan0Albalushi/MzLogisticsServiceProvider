import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/shipment.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final shipmentSearchProvider = StateProvider<String>((ref) => '');
final shipmentCityProvider = StateProvider<String>((ref) => '');
final shipmentStatusProvider = StateProvider<String?>((ref) => null);
final shipmentDateFromProvider = StateProvider<String?>((ref) => null);
final shipmentDateToProvider = StateProvider<String?>((ref) => null);
final shipmentPageProvider = StateProvider<int>((ref) => 1);

final shipmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(shipmentRepositoryProvider).list(
        page: ref.watch(shipmentPageProvider),
        search: ref.watch(shipmentSearchProvider),
        city: ref.watch(shipmentCityProvider),
        status: ref.watch(shipmentStatusProvider),
        dateFrom: ref.watch(shipmentDateFromProvider),
        dateTo: ref.watch(shipmentDateToProvider),
      );
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

    return AppPage(
      child: Column(
        children: [
          PageHeader(
            title: context.tr('shipments.title'),
            subtitle: context.tr('shipments.subtitle'),
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) {
                  ref.read(shipmentSearchProvider.notifier).state = value;
                  ref.read(shipmentPageProvider.notifier).state = 1;
                },
              ),
              FilterSearchField(
                hint: context.tr('common.cityPlaceholder'),
                onChanged: (value) {
                  ref.read(shipmentCityProvider.notifier).state = value;
                  ref.read(shipmentPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: const ['published', 'awarded', 'cancelled', 'expired'],
                value: ref.watch(shipmentStatusProvider),
                onChanged: (value) {
                  ref.read(shipmentStatusProvider.notifier).state = value;
                  ref.read(shipmentPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
              FilterDateRange(
                from: ref.watch(shipmentDateFromProvider),
                to: ref.watch(shipmentDateToProvider),
                onChanged: (from, to) {
                  ref.read(shipmentDateFromProvider.notifier).state = from;
                  ref.read(shipmentDateToProvider.notifier).state = to;
                  ref.read(shipmentPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
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
                        DataColumnSpec(context.tr('common.customer')),
                        DataColumnSpec(context.tr('shipments.cargo')),
                        DataColumnSpec(context.tr('shipments.pickup')),
                        DataColumnSpec(context.tr('shipments.delivery')),
                        DataColumnSpec(context.tr('common.quantity')),
                        DataColumnSpec(context.tr('shipments.weight')),
                        DataColumnSpec(context.tr('common.requiredDate')),
                        DataColumnSpec(context.tr('common.status')),
                        DataColumnSpec(context.tr('common.actions')),
                      ],
                      onRowTap: (item) => context.go('/shipments/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.customer?.name ?? '—'),
                        Text(item.cargoType ?? ''),
                        Text(item.pickupCity ?? ''),
                        Text(item.deliveryCity ?? ''),
                        Text('${Formatters.number(item.quantity, locale: locale)} ${item.quantityUnit ?? ''}'),
                        Text('${Formatters.number(item.weightTons, locale: locale)} ${context.tr('common.tons')}'),
                        Text(Formatters.date(item.requiredDate, locale: locale)),
                        StatusBadge(status: item.status),
                        _quoteAction(context, session, item, orgId),
                      ],
                      cardBuilder: (item) => EntityCard(
                        title: item.reference ?? '',
                        icon: Icons.local_shipping_outlined,
                        tone: IconTone.teal,
                        trailing: StatusBadge(status: item.status),
                        subtitle: item.customer?.name ?? '—',
                        meta: [
                          '${item.pickupCity ?? ''} → ${item.deliveryCity ?? ''}',
                          '${item.cargoType ?? ''} · ${Formatters.number(item.quantity, locale: locale)} ${item.quantityUnit ?? ''} · ${Formatters.number(item.weightTons, locale: locale)} ${context.tr('common.tons')}',
                          Formatters.date(item.requiredDate, locale: locale),
                        ],
                        footer: _quoteAction(context, session, item, orgId),
                        onTap: () => context.go('/shipments/${item.id}'),
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
