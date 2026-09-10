import '../../core/config/app_config.dart';
import '../../core/utils/json_utils.dart';
import 'job.dart';
import 'truck.dart';
import 'user.dart';

class ProofOfDelivery {
  const ProofOfDelivery({
    this.receiverName,
    this.receivedQuantity,
    this.otpVerified,
    this.notes,
    this.capturedAt,
  });

  final String? receiverName;
  final double? receivedQuantity;
  final bool? otpVerified;
  final String? notes;
  final String? capturedAt;

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      receiverName: asString(json['receiver_name']),
      receivedQuantity: asDouble(json['received_quantity']),
      otpVerified: json['otp_verified'] is bool ? json['otp_verified'] as bool : null,
      notes: asString(json['notes']),
      capturedAt: asString(json['captured_at']),
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    this.reference,
    this.sequence,
    this.status,
    this.plannedQuantity,
    this.deliveredQuantity,
    this.pickupAddress,
    this.pickupCity,
    this.deliveryAddress,
    this.deliveryCity,
    this.etaAt,
    this.otpCode,
    this.assignedAt,
    this.job,
    this.truck,
    this.driver,
    this.proofOfDelivery,
    this.createdAt,
  });

  final int id;
  final String? reference;
  final int? sequence;
  final String? status;
  final double? plannedQuantity;
  final double? deliveredQuantity;
  final String? pickupAddress;
  final String? pickupCity;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? etaAt;
  final String? otpCode;
  final String? assignedAt;
  final TransportJob? job;
  final Truck? truck;
  final AppUser? driver;
  final ProofOfDelivery? proofOfDelivery;
  final String? createdAt;

  bool get canAssign => status == 'unassigned' || status == 'assigned';

  String? get nextStatus {
    const flow = AppConfig.tripStatuses;
    if (status == null || status == 'completed' || status == 'cancelled') {
      return null;
    }
    final index = flow.indexOf(status!);
    if (index < 0 || index >= flow.length - 1) {
      return null;
    }
    if (status == 'unassigned') {
      return null;
    }
    return flow[index + 1];
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: asInt(json['id']) ?? 0,
      reference: asString(json['reference']),
      sequence: asInt(json['sequence']),
      status: asString(json['status']),
      plannedQuantity: asDouble(json['planned_quantity']),
      deliveredQuantity: asDouble(json['delivered_quantity']),
      pickupAddress: asString(json['pickup_address']),
      pickupCity: asString(json['pickup_city']),
      deliveryAddress: asString(json['delivery_address']),
      deliveryCity: asString(json['delivery_city']),
      etaAt: asString(json['eta_at']),
      otpCode: asString(json['otp_code']),
      assignedAt: asString(json['assigned_at']),
      job: json['job'] is Map ? TransportJob.fromJson(asMap(json['job'])) : null,
      truck: json['truck'] is Map ? Truck.fromJson(asMap(json['truck'])) : null,
      driver: json['driver'] is Map ? AppUser.fromJson(asMap(json['driver'])) : null,
      proofOfDelivery: json['proof_of_delivery'] is Map
          ? ProofOfDelivery.fromJson(asMap(json['proof_of_delivery']))
          : null,
      createdAt: asString(json['created_at']),
    );
  }
}
