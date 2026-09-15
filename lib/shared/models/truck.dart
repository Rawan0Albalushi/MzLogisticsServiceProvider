import '../../core/utils/json_utils.dart';
import 'user.dart';

class Truck {
  const Truck({
    required this.id,
    this.plateNumber,
    this.type,
    this.typeLabel,
    this.capacityTons,
    this.volumeCbm,
    this.cargoLengthM,
    this.cargoWidthM,
    this.cargoHeightM,
    this.axleCount,
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
  final String? typeLabel;
  final double? capacityTons;
  final double? volumeCbm;
  final double? cargoLengthM;
  final double? cargoWidthM;
  final double? cargoHeightM;
  final int? axleCount;
  final int? year;
  final String? make;
  final String? model;
  final String? status;
  final int? assignedDriverId;
  final AppUser? assignedDriver;
  final String? insuranceExpiresAt;

  bool get isAvailable => status == 'available';
  bool get isUnavailable => status == 'maintenance' || status == 'inactive';
  bool get isBusy => status == 'assigned';

  bool canCarry(double plannedQuantity) {
    return (capacityTons ?? 0) + 0.0001 >= plannedQuantity;
  }

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: asInt(json['id']) ?? 0,
      plateNumber: asString(json['plate_number']),
      type: asString(json['type']),
      typeLabel: asString(json['type_label']),
      capacityTons: asDouble(json['capacity_tons']),
      volumeCbm: asDouble(json['volume_cbm']),
      cargoLengthM: asDouble(json['cargo_length_m']),
      cargoWidthM: asDouble(json['cargo_width_m']),
      cargoHeightM: asDouble(json['cargo_height_m']),
      axleCount: asInt(json['axle_count']),
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
