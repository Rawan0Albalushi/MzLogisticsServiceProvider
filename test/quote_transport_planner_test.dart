import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/features/shipments/domain/quote_transport_planner.dart';

void main() {
  group('QuoteTransportPlanner', () {
    test('uses two 30t trucks in parallel for 60 tons when both exist', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 60,
        weightTons: 60,
        quantityUnit: 'tons',
        fleetCapacities: const [30, 30],
      );

      expect(plan, isNotNull);
      expect(plan!.truckCount, 2);
      expect(plan.tripCount, 2);
      expect(plan.capacityTons, 30);
      expect(plan.quantityPerTrip, 30);
      expect(plan.durationDays, 1);
    });

    test('uses two trips on one truck when only one 30t truck exists', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 60,
        weightTons: 60,
        quantityUnit: 'tons',
        fleetCapacities: const [30],
      );

      expect(plan, isNotNull);
      expect(plan!.truckCount, 1);
      expect(plan.tripCount, 2);
      expect(plan.capacityTons, 30);
      expect(plan.quantityPerTrip, 30);
      expect(plan.durationDays, 2);
    });

    test('does not invent a plan without fleet or typed capacity', () {
      expect(
        QuoteTransportPlanner.suggest(
          quantity: 60,
          weightTons: 60,
          fleetCapacities: const [],
        ),
        isNull,
      );
    });

    test('manual capacity still yields sequential trips without a fleet', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 60,
        weightTons: 60,
        fleetCapacities: const [],
        manualCapacityTons: 30,
      );

      expect(plan!.truckCount, 1);
      expect(plan.tripCount, 2);
      expect(plan.quantityPerTrip, 30);
    });

    test('does not add a second truck when one load fits', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 25,
        weightTons: 25,
        fleetCapacities: const [30, 30],
      );

      expect(plan!.truckCount, 1);
      expect(plan.tripCount, 1);
      expect(plan.quantityPerTrip, 25);
      expect(plan.capacityTons, 30);
    });

    test('prefers two 30t trucks over one 40t truck when that finishes sooner', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 60,
        weightTons: 60,
        fleetCapacities: const [40, 30],
      );

      expect(plan!.capacityTons, 30);
      expect(plan.truckCount, 2);
      expect(plan.tripCount, 2);
      expect(plan.durationDays, 1);
    });

    test('splits leftover weight evenly without exceeding capacity', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 50,
        weightTons: 50,
        fleetCapacities: const [30],
      );

      expect(plan!.tripCount, 2);
      expect(plan.quantityPerTrip, 25);
      expect(plan.capacityTons, 30);
    });

    test('limits pallet quantity by weight against truck capacity', () {
      final plan = QuoteTransportPlanner.suggest(
        quantity: 100,
        weightTons: 20,
        quantityUnit: 'pallets',
        fleetCapacities: const [10, 10],
      );

      expect(plan!.truckCount, 2);
      expect(plan.tripCount, 2);
      expect(plan.quantityPerTrip, 50);
      expect(plan.capacityTons, 10);
    });

    test('rounds split quantity up so planned total still covers the request', () {
      expect(QuoteTransportPlanner.splitQuantity(70, 3), 23.34);
    });
  });
}
