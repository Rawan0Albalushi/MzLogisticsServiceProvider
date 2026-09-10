import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';

final fleetTrucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(page: 1);
});

final fleetDriversProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).drivers(page: 1);
});

final fleetEquipmentProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).equipment(page: 1);
});

class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final trucks = ref.watch(fleetTrucksProvider);
    final drivers = ref.watch(fleetDriversProvider);
    final equipment = ref.watch(fleetEquipmentProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          PageHeader(title: context.tr('fleet.title'), subtitle: context.tr('fleet.subtitle')),
          const SizedBox(height: 12),
          Text(context.tr('fleet.belongsToCompany')),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: MetricCard(
                  label: context.tr('fleet.trucksSummary'),
                  value: trucks.asData?.value.total.toString() ?? '—',
                  icon: Icons.fire_truck_outlined,
                  onTap: () => context.go('/trucks'),
                ),
              ),
              if (session.permissions.can(AppPermissions.driversView))
                SizedBox(
                  width: 240,
                  child: MetricCard(
                    label: context.tr('fleet.driversSummary'),
                    value: drivers.asData?.value.total.toString() ?? '—',
                    icon: Icons.badge_outlined,
                    onTap: () => context.go('/drivers'),
                  ),
                ),
              SizedBox(
                width: 240,
                child: MetricCard(
                  label: context.tr('fleet.equipmentSummary'),
                  value: equipment.asData?.value.total.toString() ?? '—',
                  icon: Icons.handyman_outlined,
                  onTap: () => context.go('/equipment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: context.tr('nav.trucks'),
            child: AsyncBody(
              value: trucks,
              onRetry: () => ref.invalidate(fleetTrucksProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('trucks.empty')),
              builder: (data) {
                return Column(
                  children: [
                    for (final truck in data.items.take(6))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(truck.plateNumber ?? ''),
                        subtitle: Text('${context.l10n.truckType(truck.type)} · ${context.l10n.status(truck.status)}'),
                        onTap: () => context.go('/trucks'),
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
