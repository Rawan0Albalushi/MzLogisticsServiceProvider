import '../../core/utils/json_utils.dart';
import 'organization.dart';
import 'quotation.dart';

class Shipment {
  const Shipment({
    required this.id,
    this.reference,
    this.cargoType,
    this.cargoDescription,
    this.weightTons,
    this.volumeCbm,
    this.quantity,
    this.quantityUnit,
    this.pickupAddress,
    this.pickupCity,
    this.pickupLat,
    this.pickupLng,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryLat,
    this.deliveryLng,
    this.requiredDate,
    this.notes,
    this.status,
    this.publishedAt,
    this.customer,
    this.quotations = const [],
    this.quotationsCount,
    this.paymentBillingTrigger,
    this.paymentDueDays,
    this.paymentPrepaid = true,
    this.paymentBillingUnit = 'job',
    this.createdAt,
  });

  final int id;
  final String? reference;
  final String? cargoType;
  final String? cargoDescription;
  final double? weightTons;
  final double? volumeCbm;
  final double? quantity;
  final String? quantityUnit;
  final String? pickupAddress;
  final String? pickupCity;
  final double? pickupLat;
  final double? pickupLng;
  final String? deliveryAddress;
  final String? deliveryCity;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? requiredDate;
  final String? notes;
  final String? status;
  final String? publishedAt;
  final Organization? customer;
  final List<Quotation> quotations;
  final int? quotationsCount;
  final String? paymentBillingTrigger;
  final int? paymentDueDays;
  final bool paymentPrepaid;
  final String? paymentBillingUnit;
  final String? createdAt;

  bool quotedBy(int? organizationId) {
    if (organizationId == null) {
      return false;
    }
    return quotations.any(
      (item) => item.provider?.id == organizationId && item.status != 'withdrawn',
    );
  }

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      cargoType: asString(json['cargo_type']),
      cargoDescription: asString(json['cargo_description']),
      weightTons: asDouble(json['weight_tons']),
      volumeCbm: asDouble(json['volume_cbm']),
      quantity: asDouble(json['quantity']),
      quantityUnit: asString(json['quantity_unit']),
      pickupAddress: asString(json['pickup_address']),
      pickupCity: asString(json['pickup_city']),
      pickupLat: asDouble(json['pickup_lat']),
      pickupLng: asDouble(json['pickup_lng']),
      deliveryAddress: asString(json['delivery_address']),
      deliveryCity: asString(json['delivery_city']),
      deliveryLat: asDouble(json['delivery_lat']),
      deliveryLng: asDouble(json['delivery_lng']),
      requiredDate: asString(json['required_date']),
      notes: asString(json['notes']),
      status: asString(json['status']),
      publishedAt: asString(json['published_at']),
      customer: json['customer'] is Map ? Organization.fromJson(asMap(json['customer'])) : null,
      quotations: asMapList(json['quotations']).map(Quotation.fromJson).toList(),
      quotationsCount: asInt(json['quotations_count']),
      paymentBillingTrigger: asString(asMap(json['payment_terms'])['billing_trigger']),
      paymentDueDays: asInt(asMap(json['payment_terms'])['due_days']),
      paymentPrepaid: asBool(asMap(json['payment_terms'])['prepaid'], fallback: true),
      paymentBillingUnit: asString(asMap(json['payment_terms'])['billing_unit']) ?? 'job',
      createdAt: asString(json['created_at']),
    );
  }
}
