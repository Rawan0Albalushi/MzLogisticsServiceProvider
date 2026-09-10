import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final truckStatusProvider = StateProvider<String?>((ref) => null);
final truckPageProvider = StateProvider<int>((ref) => 1);

final trucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(
        page: ref.watch(truckPageProvider),
        status: ref.watch(truckStatusProvider),
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
    return Padding(
      padding: const EdgeInsets.all(20),
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChips(
              options: AppConfig.truckStatuses,
              selected: ref.watch(truckStatusProvider),
              onSelected: (value) {
                ref.read(truckStatusProvider.notifier).state = value;
                ref.read(truckPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
          ),
          const SizedBox(height: 16),
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
                        DataColumnSpec(context.tr('common.capacity')),
                        DataColumnSpec(context.tr('trucks.assignedDriver')),
                        DataColumnSpec(context.tr('common.status')),
                        DataColumnSpec(context.tr('common.actions')),
                      ],
                      rowCells: (item) => [
                        Text(item.plateNumber ?? ''),
                        Text(context.l10n.truckType(item.type)),
                        Text(Formatters.number(item.capacityTons)),
                        Text(item.assignedDriver?.name ?? '—'),
                        StatusBadge(status: item.status),
                        session.permissions.can(AppPermissions.fleetManage)
                            ? TextButton(
                                onPressed: () => context.go('/trucks/${item.id}/edit'),
                                child: Text(context.tr('common.edit')),
                              )
                            : const SizedBox.shrink(),
                      ],
                      cardBuilder: (item) => Card(
                        child: ListTile(
                          title: Text(item.plateNumber ?? ''),
                          subtitle: Text(
                            '${context.l10n.truckType(item.type)} · ${Formatters.number(item.capacityTons)} ${context.tr('common.tons')}',
                          ),
                          trailing: StatusBadge(status: item.status),
                          onTap: session.permissions.can(AppPermissions.fleetManage)
                              ? () => context.go('/trucks/${item.id}/edit')
                              : null,
                        ),
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
