import '../../core/utils/json_utils.dart';
import 'user.dart';

class Truck {
  const Truck({
    required this.id,
    this.plateNumber,
    this.type,
    this.capacityTons,
    this.year,
    this.make,
    this.model,
    this.status,
    this.assignedDriverId,
    this.assignedDriver,
    this.insuranceExpiresAt,
  });

  final int id;
  final String? plateNumber;
  final String? type;
  final double? capacityTons;
  final int? year;
  final String? make;
  final String? model;
  final String? status;
  final int? assignedDriverId;
  final AppUser? assignedDriver;
  final String? insuranceExpiresAt;

  bool get isAvailable => status == 'available';
  bool get isUnavailable => status == 'maintenance' || status == 'inactive';

  bool canCarry(double plannedQuantity) {
    return (capacityTons ?? 0) + 0.0001 >= plannedQuantity;
  }

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: asInt(json['id']) ?? 0,
      plateNumber: asString(json['plate_number']),
      type: asString(json['type']),
      capacityTons: asDouble(json['capacity_tons']),
      year: asInt(json['year']),
      make: asString(json['make']),
      model: asString(json['model']),
      status: asString(json['status']),
      assignedDriverId: asInt(json['assigned_driver_id']),
      assignedDriver: json['assigned_driver'] is Map
          ? AppUser.fromJson(asMap(json['assigned_driver']))
          : null,
      insuranceExpiresAt: asString(json['insurance_expires_at']),
    );
  }
}
