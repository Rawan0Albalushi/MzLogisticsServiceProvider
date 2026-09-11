import '../../core/utils/json_utils.dart';

class TruckTypeOption {
  const TruckTypeOption({
    required this.code,
    required this.name,
    required this.nameAr,
    this.id,
    this.isActive = true,
    this.isSystem = false,
    this.isPlatform = true,
    this.canManage = false,
    this.sortOrder = 0,
  });

  final int? id;
  final String code;
  final String name;
  final String nameAr;
  final bool isActive;
  final bool isSystem;
  final bool isPlatform;
  final bool canManage;
  final int sortOrder;

  String displayName(bool arabic) => arabic && nameAr.isNotEmpty ? nameAr : name;

  factory TruckTypeOption.fallback(String code) {
    return TruckTypeOption(code: code, name: code, nameAr: code);
  }

  factory TruckTypeOption.fromJson(Map<String, dynamic> json) {
    return TruckTypeOption(
      id: asInt(json['id']),
      code: asString(json['code']) ?? '',
      name: asString(json['name']) ?? '',
      nameAr: asString(json['name_ar']) ?? '',
      isActive: asBool(json['is_active'], fallback: true),
      isSystem: asBool(json['is_system']),
      isPlatform: asBool(json['is_platform'], fallback: true),
      canManage: asBool(json['can_manage']),
      sortOrder: asInt(json['sort_order']) ?? 0,
    );
  }
}
