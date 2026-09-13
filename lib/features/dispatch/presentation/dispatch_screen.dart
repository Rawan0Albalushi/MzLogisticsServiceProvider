import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../trips/presentation/trips_screen.dart';
import '../domain/dispatch_plan.dart';
import 'assign_sheet.dart';

final dispatchSearchProvider = StateProvider<String>((ref) => '');

class DispatchScreen extends ConsumerWidget {
  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.tripsAssign)) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(title: context.tr('dispatch.title'), subtitle: context.tr('dispatch.subtitle')),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                onChanged: (value) => ref.read(dispatchSearchProvider.notifier).state = value,
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              value: ref.watch(unassignedTripsProvider),
              onRetry: () => ref.invalidate(unassignedTripsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('dispatch.empty'), icon: Icons.assignment_ind_outlined),
              builder: (data) {
                final search = ref.watch(dispatchSearchProvider).trim().toLowerCase();
                final groups = DispatchJobGroup.fromTrips(data.items).where((group) {
                  if (search.isEmpty) {
                    return true;
                  }
                  final trip = group.trips.first;
                  final haystack =
                      '${group.job?.reference ?? ''} ${trip.reference ?? ''} ${trip.pickupCity ?? ''} ${trip.deliveryCity ?? ''}'
                          .toLowerCase();
                  return haystack.contains(search);
                }).toList();
                if (groups.isEmpty) {
                  return EmptyState(message: context.tr('dispatch.empty'), icon: Icons.assignment_ind_outlined);
                }
                return ListView(
                  children: [
                    for (final group in groups)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.job?.reference ?? group.trips.first.reference ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  StatusBadge(status: group.job?.status ?? group.trips.first.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${group.trips.first.pickupCity ?? ''} → ${group.trips.first.deliveryCity ?? ''}'),
                              Text(
                                context.tr('dispatch.quotedTrucks', {
                                  'count': '${group.job?.quotation?.dispatchTruckCount ?? group.trips.length}',
                                  'waiting': '${group.trips.length}',
                                }),
                              ),
                              const SizedBox(height: 8),
                              for (final trip in group.trips)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${trip.reference ?? ''} · ${context.tr('trips.planned')}: ${Formatters.number(trip.plannedQuantity)} ${context.tr('common.tons')}',
                                  ),
                                ),
                              const SizedBox(height: 12),
                              AppButton(
                                label: group.assignableNow > 1
                                    ? context.tr('dispatch.assignAll', {'count': '${group.assignableNow}'})
                                    : context.tr('common.assign'),
                                amber: true,
                                onPressed: () => showAssignSheet(
                                  context,
                                  ref,
                                  trip: group.trips.first,
                                  job: group.job,
                                ),
                              ),
                            ],
                          ),
                        ),
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
