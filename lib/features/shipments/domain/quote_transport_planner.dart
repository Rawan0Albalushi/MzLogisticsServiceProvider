/// Builds a fleet-aware quotation plan from cargo size and truck capacity.
///
/// Rules, in order:
/// 1. One trip must never exceed the quoted truck capacity.
/// 2. Cover the full requested quantity with equal trip loads.
/// 3. Prefer finishing sooner: use as many capable trucks as the load needs.
/// 4. If trucks are not enough, add sequential trips on the same trucks.
class QuoteTransportSuggestion {
  const QuoteTransportSuggestion({
    required this.truckCount,
    required this.tripCount,
    required this.capacityTons,
    required this.quantityPerTrip,
    required this.durationDays,
    required this.availableTrucks,
  });

  final int truckCount;
  final int tripCount;
  final double capacityTons;
  final double quantityPerTrip;
  final int durationDays;
  final int availableTrucks;

  int get waves => durationDays;

  bool matches({
    required int truckCount,
    required int tripCount,
    required double capacityTons,
    required double quantityPerTrip,
  }) {
    return this.truckCount == truckCount &&
        this.tripCount == tripCount &&
        (this.capacityTons - capacityTons).abs() < 0.01 &&
        (this.quantityPerTrip - quantityPerTrip).abs() < 0.01;
  }
}

class QuoteTransportPlanner {
  QuoteTransportPlanner._();

  static const double epsilon = 0.0001;

  static QuoteTransportSuggestion? suggest({
    required double quantity,
    double weightTons = 0,
    String? quantityUnit,
    required List<double> fleetCapacities,
    double? manualCapacityTons,
  }) {
    if (quantity <= 0) {
      return null;
    }

    final usable = fleetCapacities.where((capacity) => capacity > 0).toList();
    final capacities = <double>{
      if (manualCapacityTons != null && manualCapacityTons > 0) manualCapacityTons,
      ...usable,
    };
    if (capacities.isEmpty) {
      return null;
    }

    QuoteTransportSuggestion? best;
    for (final capacity in capacities) {
      final candidate = _planForCapacity(
        quantity: quantity,
        weightTons: weightTons,
        quantityUnit: quantityUnit,
        capacityTons: capacity,
        usable: usable,
      );
      if (candidate == null) {
        continue;
      }
      if (best == null || _isBetter(candidate, best)) {
        best = candidate;
      }
    }
    return best;
  }

  static int loadsNeeded({
    required double quantity,
    double weightTons = 0,
    String? quantityUnit,
    required double capacityTons,
  }) {
    final maxQty = maxQuantityPerTrip(
      quantity: quantity,
      weightTons: weightTons,
      quantityUnit: quantityUnit,
      capacityTons: capacityTons,
    );
    if (quantity <= 0 || maxQty <= 0) {
      return 1;
    }
    return (quantity / maxQty).ceil();
  }

  static double maxQuantityPerTrip({
    required double quantity,
    double weightTons = 0,
    String? quantityUnit,
    required double capacityTons,
  }) {
    if (capacityTons <= 0) {
      return 0;
    }
    if (weightTons > 0 && quantity > 0) {
      return capacityTons * quantity / weightTons;
    }
    if (_quantityIsTons(quantityUnit)) {
      return capacityTons;
    }
    return quantity;
  }

  static double splitQuantity(double quantity, int trips) {
    if (trips <= 0 || quantity <= 0) {
      return 0;
    }
    return ((quantity / trips) * 100).ceil() / 100;
  }

  static QuoteTransportSuggestion? _planForCapacity({
    required double quantity,
    required double weightTons,
    required String? quantityUnit,
    required double capacityTons,
    required List<double> usable,
  }) {
    final maxQty = maxQuantityPerTrip(
      quantity: quantity,
      weightTons: weightTons,
      quantityUnit: quantityUnit,
      capacityTons: capacityTons,
    );
    if (maxQty <= 0) {
      return null;
    }

    final trips = (quantity / maxQty).ceil();
    final capable = usable.where((item) => item + epsilon >= capacityTons).length;
    final trucks = capable == 0 ? 1 : (capable < trips ? capable : trips);
    final safeTrucks = trucks < 1 ? 1 : trucks;
    final safeTrips = trips < safeTrucks ? safeTrucks : trips;
    final days = (safeTrips / safeTrucks).ceil();

    return QuoteTransportSuggestion(
      truckCount: safeTrucks,
      tripCount: safeTrips,
      capacityTons: capacityTons,
      quantityPerTrip: splitQuantity(quantity, safeTrips),
      durationDays: days < 1 ? 1 : days,
      availableTrucks: capable,
    );
  }

  static bool _isBetter(QuoteTransportSuggestion a, QuoteTransportSuggestion b) {
    if (a.durationDays != b.durationDays) {
      return a.durationDays < b.durationDays;
    }
    if (a.tripCount != b.tripCount) {
      return a.tripCount < b.tripCount;
    }
    if (a.truckCount != b.truckCount) {
      return a.truckCount > b.truckCount;
    }
    return a.capacityTons > b.capacityTons;
  }

  static bool _quantityIsTons(String? raw) {
    final key = (raw ?? '').toLowerCase().trim();
    return key.isEmpty || key == 'ton' || key == 'tons';
  }
}
