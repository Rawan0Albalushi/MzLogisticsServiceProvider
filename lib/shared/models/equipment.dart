import '../../core/utils/json_utils.dart';

class EquipmentItem {
  const EquipmentItem({
    required this.id,
    this.name,
    this.type,
    this.quantity,
    this.status,
  });

  final int id;
  final String? name;
  final String? type;
  final int? quantity;
  final String? status;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']),
      type: asString(json['type']),
      quantity: asInt(json['quantity']),
      status: asString(json['status']),
    );
  }
}
