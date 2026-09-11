import '../../core/utils/json_utils.dart';
import 'organization.dart';
import 'shipment.dart';

class Quotation {
  const Quotation({
    required this.id,
    this.reference,
    this.shipmentRequestId,
    this.totalPrice,
    this.currency,
    this.truckCount,
    this.truckType,
    this.truckCapacityTons,
    this.tripCount,
    this.quantityPerTrip,
    this.durationDays,
    this.additionalCosts,
    this.conditions,
    this.validUntil,
    this.status,
    this.provider,
    this.shipment,
    this.createdAt,
  });

  final int id;
  final String? reference;
  final int? shipmentRequestId;
  final double? totalPrice;
  final String? currency;
  final int? truckCount;
  final String? truckType;
  final double? truckCapacityTons;
  final int? tripCount;
  final double? quantityPerTrip;
  final int? durationDays;
  final double? additionalCosts;
  final String? conditions;
  final String? validUntil;
  final String? status;
  final Organization? provider;
  final Shipment? shipment;
  final String? createdAt;

  bool get canWithdraw => status == 'submitted';

  int get dispatchTruckCount {
    final count = truckCount ?? 1;
    return count < 1 ? 1 : count;
  }

  int get plannedTripRecords {
    final trips = tripCount ?? 1;
    final trucks = dispatchTruckCount;
    return trucks > trips ? trucks : trips;
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      shipmentRequestId: asInt(json['shipment_request_id']),
      totalPrice: asDouble(json['total_price']),
      currency: asString(json['currency']),
      truckCount: asInt(json['truck_count']),
      truckType: asString(json['truck_type']),
      truckCapacityTons: asDouble(json['truck_capacity_tons']),
      tripCount: asInt(json['trip_count']),
      quantityPerTrip: asDouble(json['quantity_per_trip']),
      durationDays: asInt(json['duration_days']),
      additionalCosts: asDouble(json['additional_costs']),
      conditions: asString(json['conditions']),
      validUntil: asString(json['valid_until']),
      status: asString(json['status']),
      provider: json['provider'] is Map ? Organization.fromJson(asMap(json['provider'])) : null,
      shipment: json['shipment'] is Map ? Shipment.fromJson(asMap(json['shipment'])) : null,
      createdAt: asString(json['created_at']),
    );
  }
}

class QuotationDraft {
  const QuotationDraft({
    required this.totalPrice,
    required this.truckCount,
    required this.truckType,
    required this.truckCapacityTons,
    required this.tripCount,
    required this.quantityPerTrip,
    required this.durationDays,
    this.additionalCosts,
    this.conditions,
  });

  final double totalPrice;
  final int truckCount;
  final String truckType;
  final double truckCapacityTons;
  final int tripCount;
  final double quantityPerTrip;
  final int durationDays;
  final double? additionalCosts;
  final String? conditions;

  Map<String, dynamic> toJson() {
    return {
      'total_price': totalPrice,
      'truck_count': truckCount,
      'truck_type': truckType,
      'truck_capacity_tons': truckCapacityTons,
      'trip_count': tripCount,
      'quantity_per_trip': quantityPerTrip,
      'duration_days': durationDays,
      if (additionalCosts != null) 'additional_costs': additionalCosts,
      if (conditions != null && conditions!.isNotEmpty) 'conditions': conditions,
    };
  }
}
