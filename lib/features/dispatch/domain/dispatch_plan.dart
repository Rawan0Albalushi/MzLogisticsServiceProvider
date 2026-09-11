import '../../../shared/models/job.dart';
import '../../../shared/models/trip.dart';

class DispatchPlan {
  const DispatchPlan({
    required this.trips,
    required this.quotedTruckCount,
    this.job,
    this.truckType,
    this.truckCapacityTons,
  });

  final List<Trip> trips;
  final int quotedTruckCount;
  final TransportJob? job;
  final String? truckType;
  final double? truckCapacityTons;

  bool get isMulti => trips.length > 1;

  static DispatchPlan fromJob(TransportJob job, {Trip? focus}) {
    final quotation = job.quotation;
    final truckCount = quotation?.dispatchTruckCount ?? 1;

    if (focus != null && focus.status != 'unassigned' && focus.canAssign) {
      return DispatchPlan(
        trips: [focus],
        quotedTruckCount: truckCount,
        job: job,
        truckType: quotation?.truckType,
        truckCapacityTons: quotation?.truckCapacityTons,
      );
    }

    final unassigned = job.unassignedTrips;
    var selected = unassigned.take(truckCount).toList();
    if (focus != null && focus.status == 'unassigned') {
      selected = [
        focus,
        ...unassigned.where((trip) => trip.id != focus.id),
      ].take(truckCount).toList();
    }
    if (selected.isEmpty && focus != null) {
      selected = [focus];
    }

    return DispatchPlan(
      trips: selected,
      quotedTruckCount: truckCount,
      job: job,
      truckType: quotation?.truckType,
      truckCapacityTons: quotation?.truckCapacityTons,
    );
  }

  static DispatchPlan fromTrip(Trip trip) {
    return DispatchPlan(
      trips: [trip],
      quotedTruckCount: trip.job?.quotation?.dispatchTruckCount ?? 1,
      job: trip.job,
      truckType: trip.job?.quotation?.truckType,
      truckCapacityTons: trip.job?.quotation?.truckCapacityTons,
    );
  }
}

class DispatchJobGroup {
  const DispatchJobGroup({required this.trips, this.job});

  final List<Trip> trips;
  final TransportJob? job;

  int get assignableNow {
    final quoted = job?.quotation?.dispatchTruckCount ?? trips.length;
    return trips.length < quoted ? trips.length : quoted;
  }

  static List<DispatchJobGroup> fromTrips(List<Trip> trips) {
    final groups = <int, List<Trip>>{};
    final order = <int>[];
    for (final trip in trips) {
      final key = trip.job?.id ?? trip.id;
      if (!groups.containsKey(key)) {
        order.add(key);
        groups[key] = [];
      }
      groups[key]!.add(trip);
    }
    return [
      for (final key in order)
        DispatchJobGroup(
          job: groups[key]!.first.job,
          trips: groups[key]!,
        ),
    ];
  }
}
