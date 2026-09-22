import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/page_visuals.dart';
import '../../../../shared/providers/session_provider.dart';
import '../../../../shared/widgets/icon_well.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'dashboard_kpi.dart';

final dashboardOpenShipmentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(shipmentRepositoryProvider).list(status: 'published', page: 1);
});

final dashboardActiveJobsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(jobRepositoryProvider).list(page: 1);
});

final dashboardTransitTripsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(tripRepositoryProvider).list(status: 'in_transit', page: 1, perPage: 5);
});

class DashboardQueueGrid extends StatelessWidget {
  const DashboardQueueGrid({
    super.key,
    required this.showShipments,
    required this.showJobs,
    required this.showTrips,
  });

  final bool showShipments;
  final bool showJobs;
  final bool showTrips;

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      if (showShipments) const _ShipmentQueue(),
      if (showJobs) const _JobQueue(),
      if (showTrips) const _TripQueue(),
    ];
    if (panels.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;
        if (constraints.maxWidth >= 1000) {
          columns = 3;
        } else if (constraints.maxWidth >= 640) {
          columns = 2;
        }
        if (columns > panels.length) {
          columns = panels.length;
        }
        return Column(
          children: [
            for (var index = 0; index < panels.length; index += columns) ...[
              if (index > 0) const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var cell = index; cell < index + columns && cell < panels.length; cell++) ...[
                    if (cell > index) const SizedBox(width: 16),
                    Expanded(child: panels[cell]),
                  ],
                  if (panels.length - index < columns)
                    Spacer(flex: columns - (panels.length - index).clamp(0, columns)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShipmentQueue extends ConsumerWidget {
  const _ShipmentQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dashboardOpenShipmentsProvider);
    return _QueueCard(
      title: context.tr('dashboard.openQueue'),
      icon: Icons.local_shipping_outlined,
      tone: IconTone.teal,
      onViewAll: () => context.go('/shipments'),
      onRetry: () => ref.invalidate(dashboardOpenShipmentsProvider),
      value: value,
      items: (data) {
        return data.items.take(5).map((item) {
          return _QueueRowData(
            title: _reference(item.reference),
            meta: _routeMeta(context, item.customer?.name, item.pickupCity, item.deliveryCity),
            status: item.status,
            onTap: () => context.go('/shipments/${item.id}'),
          );
        }).toList();
      },
    );
  }
}

class _JobQueue extends ConsumerWidget {
  const _JobQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dashboardActiveJobsProvider);
    return _QueueCard(
      title: context.tr('dashboard.activeJobsQueue'),
      icon: Icons.work_outline_rounded,
      tone: IconTone.warning,
      onViewAll: () => context.go('/jobs'),
      onRetry: () => ref.invalidate(dashboardActiveJobsProvider),
      value: value,
      items: (data) {
        return data.items
            .where((job) => job.status == 'pending_dispatch' || job.status == 'in_progress')
            .take(5)
            .map((job) {
          return _QueueRowData(
            title: _reference(job.reference),
            meta: _party(job.customer?.name),
            status: job.status,
            onTap: () => context.go('/jobs/${job.id}'),
          );
        }).toList();
      },
    );
  }
}

class _TripQueue extends ConsumerWidget {
  const _TripQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dashboardTransitTripsProvider);
    return _QueueCard(
      title: context.tr('dashboard.transitQueue'),
      icon: Icons.route_outlined,
      tone: IconTone.success,
      onViewAll: () => context.go('/trips'),
      onRetry: () => ref.invalidate(dashboardTransitTripsProvider),
      value: value,
      items: (data) {
        return data.items.take(5).map((trip) {
          return _QueueRowData(
            title: _reference(trip.reference),
            meta: _routeMeta(context, trip.driver?.name, trip.pickupCity, trip.deliveryCity),
            status: trip.status,
            onTap: () => context.go('/trips/${trip.id}'),
          );
        }).toList();
      },
    );
  }
}

class _QueueRowData {
  const _QueueRowData({
    required this.title,
    required this.meta,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String meta;
  final String? status;
  final VoidCallback onTap;
}

class _QueueCard<T> extends StatelessWidget {
  const _QueueCard({
    required this.title,
    required this.icon,
    required this.tone,
    required this.onViewAll,
    required this.onRetry,
    required this.value,
    required this.items,
  });

  final String title;
  final IconData icon;
  final IconTone tone;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;
  final AsyncValue<T> value;
  final List<_QueueRowData> Function(T data) items;

  @override
  Widget build(BuildContext context) {
    final viewAll = context.tr('dashboard.viewAll');
    return DecoratedBox(
      decoration: dashboardSurfaceDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconWell(icon: icon, tone: tone, size: IconWellSize.sm),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  child: Text(viewAll, semanticsLabel: '$viewAll, $title'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            value.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(context.tr('common.error'), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
                  ],
                ),
              ),
              data: (data) {
                final rows = items(data);
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      context.tr('dashboard.queueEmpty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < rows.length; index++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: index == rows.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: _QueueRow(row: rows[index]),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.row});

  final _QueueRowData row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      hoverColor: AppColors.rowHover,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusBadge(status: row.status),
          ],
        ),
      ),
    );
  }
}

String _reference(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '—';
  }
  return trimmed;
}

String _party(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '—';
  }
  return trimmed;
}

String _routeMeta(BuildContext context, String? party, String? pickup, String? delivery) {
  final arrow = Directionality.of(context) == TextDirection.rtl ? '←' : '→';
  return '${_party(party)} · ${_party(pickup)} $arrow ${_party(delivery)}';
}
