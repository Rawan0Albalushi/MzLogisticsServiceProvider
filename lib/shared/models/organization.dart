import '../../core/utils/json_utils.dart';
import 'document.dart';
import 'truck.dart';
import 'user.dart';

class Organization {
  const Organization({
    required this.id,
    this.type,
    this.accountType,
    this.name,
    this.nameAr,
    this.commercialRegister,
    this.taxNumber,
    this.email,
    this.phone,
    this.city,
    this.country,
    this.address,
    this.status,
    this.verificationNotes,
    this.commissionRate,
    this.createdAt,
    this.users = const [],
    this.trucks = const [],
    this.documents = const [],
  });

  final int id;
  final String? type;
  final String? accountType;
  final String? name;
  final String? nameAr;
  final String? commercialRegister;
  final String? taxNumber;
  final String? email;
  final String? phone;
  final String? city;
  final String? country;
  final String? address;
  final String? status;
  final String? verificationNotes;
  final double? commissionRate;
  final String? createdAt;
  final List<AppUser> users;
  final List<Truck> trucks;
  final List<CompanyDocument> documents;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: asInt(json['id']) ?? 0,
      type: asString(json['type']),
      accountType: asString(json['account_type']),
      name: asString(json['name']),
      nameAr: asString(json['name_ar']),
      commercialRegister: asString(json['commercial_register']),
      taxNumber: asString(json['tax_number']),
      email: asString(json['email']),
      phone: asString(json['phone']),
      city: asString(json['city']),
      country: asString(json['country']),
      address: asString(json['address']),
      status: asString(json['status']),
      verificationNotes: asString(json['verification_notes']),
      commissionRate: asDouble(json['commission_rate']),
      createdAt: asString(json['created_at']),
      users: asMapList(json['users']).map(AppUser.fromJson).toList(),
      trucks: asMapList(json['trucks']).map(Truck.fromJson).toList(),
      documents: asMapList(json['documents']).map(CompanyDocument.fromJson).toList(),
    );
  }
}
