import '../../core/utils/json_utils.dart';

class EquipmentItem {
  const EquipmentItem({
    required this.id,
    this.name,
    this.type,
    this.quantity,
    this.status,
    this.truckId,
    this.truckPlate,
  });

  final int id;
  final String? name;
  final String? type;
  final int? quantity;
  final String? status;
  final int? truckId;
  final String? truckPlate;

  bool get isCompanyEquipment => truckId == null;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    final truck = json['truck'] is Map ? asMap(json['truck']) : null;
    return EquipmentItem(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']),
      type: asString(json['type']),
      quantity: asInt(json['quantity']),
      status: asString(json['status']),
      truckId: asInt(json['truck_id']),
      truckPlate: truck == null ? null : asString(truck['plate_number']),
    );
  }
}
