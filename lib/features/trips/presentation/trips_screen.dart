import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final tripStatusProvider = StateProvider<String?>((ref) => null);
final tripPageProvider = StateProvider<int>((ref) => 1);

final tripsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(tripRepositoryProvider).list(
        page: ref.watch(tripPageProvider),
        status: ref.watch(tripStatusProvider),
      );
});

final unassignedTripsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(tripRepositoryProvider).list(status: 'unassigned', page: 1);
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.tripsView)) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(title: context.tr('trips.title'), subtitle: context.tr('trips.subtitle')),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChips(
              options: AppConfig.tripStatuses,
              selected: ref.watch(tripStatusProvider),
              onSelected: (value) {
                ref.read(tripStatusProvider.notifier).state = value;
                ref.read(tripPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(tripsProvider),
              onRetry: () => ref.invalidate(tripsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('trips.empty'), icon: Icons.route_outlined),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<Trip>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('common.reference')),
                        DataColumnSpec(context.tr('common.job')),
                        DataColumnSpec(context.tr('trips.sequence')),
                        DataColumnSpec(context.tr('common.truck')),
                        DataColumnSpec(context.tr('common.driver')),
                        DataColumnSpec(context.tr('common.status')),
                      ],
                      onRowTap: (item) => context.go('/trips/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.job?.reference ?? ''),
                        Text('${item.sequence ?? ''}'),
                        Text(item.truck?.plateNumber ?? '—'),
                        Text(item.driver?.name ?? '—'),
                        StatusBadge(status: item.status),
                      ],
                      cardBuilder: (item) => Card(
                        child: ListTile(
                          title: Text(item.reference ?? ''),
                          subtitle: Text(
                            '${context.tr('common.job')} ${item.job?.reference ?? '—'} · ${item.pickupCity ?? ''} → ${item.deliveryCity ?? ''}',
                          ),
                          trailing: StatusBadge(status: item.status),
                          onTap: () => context.go('/trips/${item.id}'),
                        ),
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(tripPageProvider.notifier).state = page,
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
