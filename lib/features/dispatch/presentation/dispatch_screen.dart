import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/models/user.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../fleet/presentation/fleet_screen.dart';
import '../../trips/presentation/trip_detail_screen.dart';
import '../../trips/presentation/trips_screen.dart';

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
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(unassignedTripsProvider),
              onRetry: () => ref.invalidate(unassignedTripsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('dispatch.empty'), icon: Icons.assignment_ind_outlined),
              builder: (data) {
                return ListView(
                  children: [
                    for (final trip in data.items)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(trip.reference ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  StatusBadge(status: trip.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${trip.pickupCity ?? ''} → ${trip.deliveryCity ?? ''}'),
                              Text('${context.tr('trips.planned')}: ${Formatters.number(trip.plannedQuantity)} ${context.tr('common.tons')}'),
                              Text('${context.tr('common.job')}: ${trip.job?.reference ?? '—'}'),
                              const SizedBox(height: 12),
                              AppButton(
                                label: context.tr('common.assign'),
                                amber: true,
                                onPressed: () => showAssignSheet(context, ref, trip),
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

Future<void> showAssignSheet(BuildContext context, WidgetRef ref, Trip trip) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => AssignTripSheet(trip: trip),
  );
}

class AssignTripSheet extends ConsumerStatefulWidget {
  const AssignTripSheet({super.key, required this.trip});

  final Trip trip;

  @override
  ConsumerState<AssignTripSheet> createState() => _AssignTripSheetState();
}

class _AssignTripSheetState extends ConsumerState<AssignTripSheet> {
  int? _truckId;
  int? _driverId;
  String? _error;
  var _loading = false;

  @override
  Widget build(BuildContext context) {
    final trucks = ref.watch(fleetTrucksProvider);
    final drivers = ref.watch(fleetDriversProvider);
    final planned = widget.trip.plannedQuantity ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('dispatch.queue'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.tr('dispatch.capacityHint', {'quantity': Formatters.number(planned)})),
          const SizedBox(height: 16),
          trucks.when(
            data: (page) {
              return AppDropdown<int>(
                label: context.tr('dispatch.selectTruck'),
                value: _truckId,
                required: true,
                items: [
                  for (final truck in page.items)
                    DropdownMenuItem(
                      value: truck.id,
                      child: Text(_truckLabel(context, truck, planned)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _truckId = value;
                  _error = _validate(page.items, drivers.asData?.value.items ?? const []);
                }),
              );
            },
            loading: () => const LoadingState(),
            error: (_, _) => Text(context.tr('common.error')),
          ),
          const SizedBox(height: 12),
          drivers.when(
            data: (page) {
              return AppDropdown<int>(
                label: context.tr('dispatch.selectDriver'),
                value: _driverId,
                required: true,
                items: [
                  for (final driver in page.items)
                    DropdownMenuItem(
                      value: driver.id,
                      child: Text(_driverLabel(context, driver)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _driverId = value;
                  _error = _validate(trucks.asData?.value.items ?? const [], page.items);
                }),
              );
            },
            loading: () => const LoadingState(),
            error: (_, _) => Text(context.tr('common.error')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF8B2E2E))),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: context.tr('common.assign'),
            expanded: true,
            loading: _loading,
            onPressed: _error != null || _truckId == null || _driverId == null ? null : _assign,
          ),
        ],
      ),
    );
  }

  String _truckLabel(BuildContext context, Truck truck, double planned) {
    final base = '${truck.plateNumber ?? ''} · ${context.l10n.truckType(truck.type)} · ${Formatters.number(truck.capacityTons)} ${context.tr('common.tons')}';
    if (truck.isUnavailable || !truck.canCarry(planned)) {
      return '$base (${context.tr('common.unavailable')})';
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
    if (!widget.trip.canAssign) {
      return context.tr('dispatch.invalidState');
    }
    final truck = trucks.where((item) => item.id == _truckId).firstOrNull;
    final driver = drivers.where((item) => item.id == _driverId).firstOrNull;
    if (truck != null) {
      if (truck.isUnavailable) {
        return context.tr('dispatch.truckUnavailable');
      }
      if (!truck.canCarry(widget.trip.plannedQuantity ?? 0)) {
        return context.tr('dispatch.overCapacity');
      }
    }
    if (driver != null && (driver.driverProfile?.isInactive ?? false)) {
      return context.tr('dispatch.driverUnavailable');
    }
    return null;
  }

  Future<void> _assign() async {
    setState(() => _loading = true);
    try {
      await ref.read(tripRepositoryProvider).assign(
            widget.trip.id,
            truckId: _truckId!,
            driverId: _driverId!,
          );
      ref.invalidate(unassignedTripsProvider);
      ref.invalidate(tripsProvider);
      ref.invalidate(tripDetailProvider(widget.trip.id));
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnack(context, context.tr('dispatch.assignSuccess'));
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
