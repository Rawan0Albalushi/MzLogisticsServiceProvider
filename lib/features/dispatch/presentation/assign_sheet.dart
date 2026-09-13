import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/models/user.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../fleet/presentation/fleet_screen.dart';
import '../../jobs/presentation/jobs_screen.dart';
import '../../trips/presentation/trips_screen.dart';
import '../domain/dispatch_plan.dart';

final dispatchTrucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(page: 1, perPage: 100);
});

final dispatchDriversProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).drivers(page: 1, perPage: 100);
});

Future<void> showAssignSheet(
  BuildContext context,
  WidgetRef ref, {
  Trip? trip,
  TransportJob? job,
}) async {
  var resolved = job;
  final jobId = job?.id ?? trip?.job?.id;
  if (jobId != null) {
    final quoted = resolved?.dispatchTruckCount ?? 1;
    if (resolved == null || resolved.quotation == null || resolved.unassignedTrips.length < quoted) {
      try {
        resolved = await ref.read(jobRepositoryProvider).show(jobId);
      } on ApiException catch (error) {
        if (context.mounted) {
          showAppSnack(context, error.message);
        }
        return;
      }
    }
  }

  if (!context.mounted) {
    return;
  }

  if (resolved == null && trip == null) {
    return;
  }

  final plan = resolved != null
      ? DispatchPlan.fromJob(resolved, focus: trip)
      : DispatchPlan.fromTrip(trip!);
  if (plan.trips.isEmpty) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => AssignTripSheet(plan: plan),
  );
}

class AssignTripSheet extends ConsumerStatefulWidget {
  const AssignTripSheet({super.key, required this.plan});

  final DispatchPlan plan;

  @override
  ConsumerState<AssignTripSheet> createState() => _AssignTripSheetState();
}

class _AssignTripSheetState extends ConsumerState<AssignTripSheet> {
  late List<int?> _truckIds;
  late List<int?> _driverIds;
  String? _error;
  var _loading = false;

  DispatchPlan get _plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _truckIds = List<int?>.filled(_plan.trips.length, null);
    _driverIds = List<int?>.filled(_plan.trips.length, null);
  }

  bool get _ready {
    for (var index = 0; index < _plan.trips.length; index++) {
      if (_truckIds[index] == null || _driverIds[index] == null) {
        return false;
      }
    }
    return _error == null && !_loading;
  }

  @override
  Widget build(BuildContext context) {
    final trucks = ref.watch(dispatchTrucksProvider);
    final drivers = ref.watch(dispatchDriversProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final quotedType = _plan.truckType;
    final quotedCapacity = _plan.truckCapacityTons;

    final sheetHeight = MediaQuery.sizeOf(context).height * (MediaQuery.sizeOf(context).width < 600 ? 0.88 : 0.75);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        context.tr('dispatch.queue'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _plan.job?.reference ?? _plan.trips.first.reference ?? '',
                        style: const TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('dispatch.fleetPlan', {
                      'count': '${_plan.quotedTruckCount}',
                      'needed': '${_plan.trips.length}',
                    }),
                    style: const TextStyle(height: 1.45),
                  ),
                  if (quotedType != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.tr('dispatch.fleetPlanType', {
                        'type': context.l10n.truckType(quotedType, label: _plan.truckTypeLabel),
                        'capacity': Formatters.number(quotedCapacity, locale: locale),
                      }),
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: trucks.when(
                loading: () => const LoadingState(),
                error: (_, _) => Text(context.tr('common.error')),
                data: (truckPage) {
                  return drivers.when(
                    loading: () => const LoadingState(),
                    error: (_, _) => Text(context.tr('common.error')),
                    data: (driverPage) {
                      return ListView.separated(
                        itemCount: _plan.trips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final trip = _plan.trips[index];
                          final planned = trip.plannedQuantity ?? 0;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const IconWell(
                                      icon: Icons.fire_truck_outlined,
                                      tone: IconTone.teal,
                                      size: IconWellSize.sm,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr('dispatch.slotTitle', {
                                              'n': '${index + 1}',
                                              'trip': trip.reference ?? '',
                                            }),
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            context.tr('dispatch.capacityHint', {
                                              'quantity': Formatters.number(planned, locale: locale),
                                            }),
                                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AppDropdown<int>(
                                  key: ValueKey('dispatch-truck-$index-${_truckIds[index]}'),
                                  label: context.tr('dispatch.selectTruck'),
                                  value: _truckIds[index],
                                  required: true,
                                  items: [
                                    for (final truck in truckPage.items)
                                      DropdownMenuItem(
                                        value: truck.id,
                                        child: Text(_truckLabel(context, truck, trip, quotedType)),
                                      ),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _truckIds[index] = value;
                                    _error = _validate(truckPage.items, driverPage.items);
                                  }),
                                ),
                                const SizedBox(height: 12),
                                AppDropdown<int>(
                                  key: ValueKey('dispatch-driver-$index-${_driverIds[index]}'),
                                  label: context.tr('dispatch.selectDriver'),
                                  value: _driverIds[index],
                                  required: true,
                                  items: [
                                    for (final driver in driverPage.items)
                                      DropdownMenuItem(
                                        value: driver.id,
                                        child: Text(_driverLabel(context, driver)),
                                      ),
                                  ],
                                  onChanged: (value) => setState(() {
                                    _driverIds[index] = value;
                                    _error = _validate(truckPage.items, driverPage.items);
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: _plan.isMulti
                  ? context.tr('dispatch.assignAll', {'count': '${_plan.trips.length}'})
                  : context.tr('common.assign'),
              amber: true,
              icon: Icons.assignment_turned_in_outlined,
              expanded: true,
              loading: _loading,
              onPressed: _ready
                  ? () => _assign(
                        trucks.asData?.value.items ?? const [],
                        drivers.asData?.value.items ?? const [],
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _truckLabel(BuildContext context, Truck truck, Trip trip, String? quotedType) {
    final planned = trip.plannedQuantity ?? 0;
    final base =
        '${truck.plateNumber ?? ''} · ${context.l10n.truckType(truck.type, label: truck.typeLabel)} · ${Formatters.number(truck.capacityTons)} ${context.tr('common.tons')}';
    final currentTruck = trip.truck?.id == truck.id;
    if (truck.isUnavailable || (!currentTruck && truck.isBusy) || !truck.canCarry(planned)) {
      return '$base (${context.tr('common.unavailable')})';
    }
    if (quotedType != null && truck.type != null && truck.type != quotedType) {
      return '$base (${context.tr('dispatch.typeMismatch')})';
    }
    return base;
  }

  String _driverLabel(BuildContext context, AppUser driver) {
    final status = driver.driverProfile?.status;
    final label = driver.name ?? '';
    if (status != null && status != 'available') {
      return '$label (${context.l10n.status(status)})';
    }
    return label;
  }

  String? _validate(List<Truck> trucks, List<AppUser> drivers) {
    final selectedTrucks = <int>{};
    final selectedDrivers = <int>{};

    for (var index = 0; index < _plan.trips.length; index++) {
      final trip = _plan.trips[index];
      if (!trip.canAssign) {
        return context.tr('dispatch.invalidState');
      }

      final truckId = _truckIds[index];
      final driverId = _driverIds[index];
      if (truckId != null) {
        if (!selectedTrucks.add(truckId)) {
          return context.tr('dispatch.duplicateTruck');
        }
        final truck = trucks.where((item) => item.id == truckId).firstOrNull;
        if (truck != null) {
          final currentTruck = trip.truck?.id == truck.id;
          if (truck.isUnavailable || (!currentTruck && truck.isBusy)) {
            return context.tr('dispatch.truckUnavailable');
          }
          if (!truck.canCarry(trip.plannedQuantity ?? 0)) {
            return context.tr('dispatch.overCapacity');
          }
        }
      }
      if (driverId != null) {
        if (!selectedDrivers.add(driverId)) {
          return context.tr('dispatch.duplicateDriver');
        }
        final driver = drivers.where((item) => item.id == driverId).firstOrNull;
        if (driver != null) {
          final currentDriver = trip.driver?.id == driver.id;
          if (!currentDriver &&
              ((driver.driverProfile?.isInactive ?? false) || (driver.driverProfile?.isOnTrip ?? false))) {
            return context.tr('dispatch.driverUnavailable');
          }
        }
      }
    }
    return null;
  }

  Future<void> _assign(List<Truck> trucks, List<AppUser> drivers) async {
    final error = _validate(trucks, drivers);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _loading = true);
    try {
      for (var index = 0; index < _plan.trips.length; index++) {
        await ref.read(tripRepositoryProvider).assign(
              _plan.trips[index].id,
              truckId: _truckIds[index]!,
              driverId: _driverIds[index]!,
            );
      }
      ref.invalidate(unassignedTripsProvider);
      ref.invalidate(tripsProvider);
      ref.invalidate(jobsProvider);
      ref.invalidate(dispatchTrucksProvider);
      ref.invalidate(dispatchDriversProvider);
      ref.invalidate(fleetTrucksProvider);
      ref.invalidate(fleetDriversProvider);
      final jobId = _plan.job?.id ?? _plan.trips.first.job?.id;
      if (jobId != null) {
        ref.invalidate(jobDetailProvider(jobId));
      }
      for (final trip in _plan.trips) {
        ref.invalidate(tripDetailProvider(trip.id));
      }
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnack(
          context,
          _plan.isMulti
              ? context.tr('dispatch.assignSuccessMany', {'count': '${_plan.trips.length}'})
              : context.tr('dispatch.assignSuccess'),
        );
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
