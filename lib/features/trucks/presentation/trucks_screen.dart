import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final truckStatusProvider = StateProvider<String?>((ref) => null);
final truckSearchProvider = StateProvider<String>((ref) => '');
final truckPageProvider = StateProvider<int>((ref) => 1);

final trucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(
        page: ref.watch(truckPageProvider),
        status: ref.watch(truckStatusProvider),
        search: ref.watch(truckSearchProvider),
      );
});

class TrucksScreen extends ConsumerWidget {
  const TrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: Column(
        children: [
          PageHeader(
            title: context.tr('trucks.title'),
            subtitle: context.tr('app.companyFleetNote'),
            actions: [
              if (session.permissions.can(AppPermissions.fleetManage))
                AppButton(
                  label: context.tr('trucks.add'),
                  icon: Icons.add,
                  onPressed: () => context.go('/trucks/new'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) {
                  ref.read(truckSearchProvider.notifier).state = value;
                  ref.read(truckPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: AppConfig.truckStatuses,
                value: ref.watch(truckStatusProvider),
                onChanged: (value) {
                  ref.read(truckStatusProvider.notifier).state = value;
                  ref.read(truckPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              value: ref.watch(trucksProvider),
              onRetry: () => ref.invalidate(trucksProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('trucks.empty')),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<Truck>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('trucks.plate')),
                        DataColumnSpec(context.tr('common.type')),
                        DataColumnSpec(context.tr('trucks.make')),
                        DataColumnSpec(context.tr('trucks.model')),
                        DataColumnSpec(context.tr('trucks.year')),
                        DataColumnSpec(context.tr('common.capacity')),
                        DataColumnSpec(context.tr('trucks.assignedDriver')),
                        DataColumnSpec(context.tr('trucks.insurance')),
                        DataColumnSpec(context.tr('common.status')),
                        DataColumnSpec(context.tr('common.actions')),
                      ],
                      rowCells: (item) => [
                        Text(item.plateNumber ?? ''),
                        Text(context.l10n.truckType(item.type, label: item.typeLabel)),
                        Text(item.make ?? '—'),
                        Text(item.model ?? '—'),
                        Text(item.year?.toString() ?? '—'),
                        Text('${Formatters.number(item.capacityTons, locale: locale)} ${context.tr('common.tons')}'),
                        Text(item.assignedDriver?.name ?? '—'),
                        Text(Formatters.date(item.insuranceExpiresAt, locale: locale)),
                        StatusBadge(status: item.status),
                        session.permissions.can(AppPermissions.fleetManage)
                            ? TextButton(
                                onPressed: () => context.go('/trucks/${item.id}/edit'),
                                child: Text(context.tr('common.edit')),
                              )
                            : const SizedBox.shrink(),
                      ],
                      cardBuilder: (item) => EntityCard(
                        title: item.plateNumber ?? '',
                        icon: Icons.fire_truck_outlined,
                        tone: IconTone.teal,
                        trailing: StatusBadge(status: item.status),
                        meta: [
                          context.l10n.truckType(item.type, label: item.typeLabel),
                          [item.make, item.model].where((value) => value != null && value.isNotEmpty).join(' '),
                          '${Formatters.number(item.capacityTons, locale: locale)} ${context.tr('common.tons')}',
                          item.assignedDriver?.name ?? '',
                        ],
                        onTap: session.permissions.can(AppPermissions.fleetManage)
                            ? () => context.go('/trucks/${item.id}/edit')
                            : null,
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(truckPageProvider.notifier).state = page,
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
