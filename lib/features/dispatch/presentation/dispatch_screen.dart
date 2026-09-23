import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/metric_card.dart';
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
    if (!ref
        .watch(sessionProvider)
        .permissions
        .can(AppPermissions.tripsAssign)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;

    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('dispatch.title'),
            subtitle: context.tr('dispatch.subtitle'),
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) =>
                    ref.read(dispatchSearchProvider.notifier).state = value,
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(unassignedTripsProvider),
            onRetry: () => ref.invalidate(unassignedTripsProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(
              message: context.tr('dispatch.empty'),
              icon: Icons.assignment_ind_outlined,
            ),
            builder: (data) {
              final search = ref
                  .watch(dispatchSearchProvider)
                  .trim()
                  .toLowerCase();
              final groups = DispatchJobGroup.fromTrips(data.items).where((
                group,
              ) {
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
                return EmptyState(
                  message: context.tr('dispatch.empty'),
                  icon: Icons.assignment_ind_outlined,
                );
              }

              final waitingTrips = groups.fold<int>(
                0,
                (sum, group) => sum + group.trips.length,
              );
              final quotedTrucks = groups.fold<int>(
                0,
                (sum, group) =>
                    sum +
                    (group.job?.quotation?.dispatchTruckCount ??
                        group.trips.length),
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = Breakpoints.metricColumns(
                        constraints.maxWidth,
                      ).clamp(1, 3);
                      final gap = 12.0;
                      final width =
                          (constraints.maxWidth - (gap * (columns - 1))) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: MetricCard(
                              label: context.tr('dispatch.waitingJobs'),
                              value: '${groups.length}',
                              icon: Icons.work_outline_rounded,
                              tone: IconTone.warning,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: MetricCard(
                              label: context.tr('dispatch.waitingTrips'),
                              value: '$waitingTrips',
                              icon: Icons.route_outlined,
                              tone: IconTone.coral,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: MetricCard(
                              label: context.tr('dispatch.quotedNeed'),
                              value: '$quotedTrucks',
                              icon: Icons.fire_truck_outlined,
                              tone: IconTone.teal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _DispatchGroupCard(group: groups[i], locale: locale),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DispatchGroupCard extends ConsumerWidget {
  const _DispatchGroupCard({required this.group, required this.locale});

  final DispatchJobGroup group;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = group.job;
    final first = group.trips.first;
    final route = '${first.pickupCity ?? ''} → ${first.deliveryCity ?? ''}';
    final quoted = job?.quotation?.dispatchTruckCount ?? group.trips.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconWell(
                  icon: Icons.assignment_ind_outlined,
                  tone: IconTone.warning,
                  size: IconWellSize.md,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job?.reference ??
                            first.reference ??
                            context.tr('dispatch.queue'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(status: job?.status ?? first.status),
                          if (route.trim() != '→')
                            DetailChip(
                              label: route,
                              icon: Icons.route_outlined,
                            ),
                          DetailChip(
                            label: context.tr('dispatch.quotedTrucks', {
                              'count': '$quoted',
                              'waiting': '${group.trips.length}',
                            }),
                            icon: Icons.local_shipping_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('dispatch.tripsInQueue'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final trip in group.trips) ...[
              _TripQueueTile(trip: trip, locale: locale),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: group.assignableNow > 1
                      ? context.tr('dispatch.assignAll', {
                          'count': '${group.assignableNow}',
                        })
                      : context.tr('common.assign'),
                  amber: true,
                  icon: Icons.assignment_turned_in_outlined,
                  onPressed: () => showAssignSheet(
                    context,
                    ref,
                    trip: group.trips.first,
                    job: job,
                  ),
                ),
                if (job != null)
                  AppButton(
                    label: context.tr('dispatch.openJob'),
                    outlined: true,
                    icon: Icons.work_outline_rounded,
                    onPressed: () => context.go('/jobs/${job.id}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripQueueTile extends StatelessWidget {
  const _TripQueueTile({required this.trip, required this.locale});

  final Trip trip;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const IconWell(
            icon: Icons.route_outlined,
            tone: IconTone.success,
            size: IconWellSize.sm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.reference ?? context.tr('trips.detailTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.tr('trips.planned')}: ${Formatters.number(trip.plannedQuantity, locale: locale)} ${context.tr('common.tons')}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          StatusBadge(status: trip.status),
        ],
      ),
    );
  }
}
