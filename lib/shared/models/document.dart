import '../../core/utils/json_utils.dart';

class CompanyDocument {
  const CompanyDocument({
    required this.id,
    this.type,
    this.title,
    this.status,
    this.expiresAt,
  });

  final int id;
  final String? type;
  final String? title;
  final String? status;
  final String? expiresAt;

  factory CompanyDocument.fromJson(Map<String, dynamic> json) {
    return CompanyDocument(
      id: asInt(json['id']) ?? 0,
      type: asString(json['type']),
      title: asString(json['title']),
      status: asString(json['status']),
      expiresAt: asString(json['expires_at']),
    );
  }
}

class ComplianceItem {
  const ComplianceItem({
    required this.title,
    required this.category,
    this.expiresAt,
    this.status,
    this.owner,
  });

  final String title;
  final String category;
  final String? expiresAt;
  final String? status;
  final String? owner;
}
