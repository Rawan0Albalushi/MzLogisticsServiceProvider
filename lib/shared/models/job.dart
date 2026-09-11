import '../../core/utils/json_utils.dart';
import 'organization.dart';
import 'quotation.dart';
import 'shipment.dart';
import 'trip.dart';

class TransportJob {
  const TransportJob({
    required this.id,
    this.reference,
    this.status,
    this.totalPrice,
    this.currency,
    this.totalQuantity,
    this.deliveredQuantity,
    this.progressPercent,
    this.startedAt,
    this.completedAt,
    this.customer,
    this.provider,
    this.shipment,
    this.quotation,
    this.trips = const [],
    this.createdAt,
  });

  final int id;
  final String? reference;
  final String? status;
  final double? totalPrice;
  final String? currency;
  final double? totalQuantity;
  final double? deliveredQuantity;
  final double? progressPercent;
  final String? startedAt;
  final String? completedAt;
  final Organization? customer;
  final Organization? provider;
  final Shipment? shipment;
  final Quotation? quotation;
  final List<Trip> trips;
  final String? createdAt;

  List<Trip> get unassignedTrips =>
      trips.where((trip) => trip.status == 'unassigned').toList();

  int get dispatchTruckCount => quotation?.dispatchTruckCount ?? 1;

  factory TransportJob.fromJson(Map<String, dynamic> json) {
    return TransportJob(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      status: asString(json['status']),
      totalPrice: asDouble(json['total_price']),
      currency: asString(json['currency']),
      totalQuantity: asDouble(json['total_quantity']),
      deliveredQuantity: asDouble(json['delivered_quantity']),
      progressPercent: asDouble(json['progress_percent']),
      startedAt: asString(json['started_at']),
      completedAt: asString(json['completed_at']),
      customer: json['customer'] is Map ? Organization.fromJson(asMap(json['customer'])) : null,
      provider: json['provider'] is Map ? Organization.fromJson(asMap(json['provider'])) : null,
      shipment: json['shipment'] is Map ? Shipment.fromJson(asMap(json['shipment'])) : null,
      quotation: json['quotation'] is Map ? Quotation.fromJson(asMap(json['quotation'])) : null,
      trips: asMapList(json['trips']).map(Trip.fromJson).toList(),
      createdAt: asString(json['created_at']),
    );
  }
}
