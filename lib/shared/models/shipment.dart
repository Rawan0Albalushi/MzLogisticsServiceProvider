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
    this.deliveryAddress,
    this.deliveryCity,
    this.requiredDate,
    this.notes,
    this.status,
    this.publishedAt,
    this.customer,
    this.quotations = const [],
    this.quotationsCount,
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
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? requiredDate;
  final String? notes;
  final String? status;
  final String? publishedAt;
  final Organization? customer;
  final List<Quotation> quotations;
  final int? quotationsCount;
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
      deliveryAddress: asString(json['delivery_address']),
      deliveryCity: asString(json['delivery_city']),
      requiredDate: asString(json['required_date']),
      notes: asString(json['notes']),
      status: asString(json['status']),
      publishedAt: asString(json['published_at']),
      customer: json['customer'] is Map ? Organization.fromJson(asMap(json['customer'])) : null,
      quotations: asMapList(json['quotations']).map(Quotation.fromJson).toList(),
      quotationsCount: asInt(json['quotations_count']),
      createdAt: asString(json['created_at']),
    );
  }
}
