import '../../core/utils/json_utils.dart';
import 'user.dart';

class DriverInviteResult {
  const DriverInviteResult({
    required this.driver,
    required this.inviteUrl,
    required this.whatsappSent,
  });

  final AppUser driver;
  final String inviteUrl;
  final bool whatsappSent;

  factory DriverInviteResult.fromJson(Map<String, dynamic> json) {
    return DriverInviteResult(
      driver: AppUser.fromJson(asMap(json['driver'])),
      inviteUrl: asString(json['invite_url']) ?? '',
      whatsappSent: asBool(json['whatsapp_sent']),
    );
  }
}

class DriverImportRow {
  const DriverImportRow({
    required this.row,
    required this.name,
    this.phone,
    required this.inviteUrl,
    required this.whatsappSent,
  });

  final int row;
  final String name;
  final String? phone;
  final String inviteUrl;
  final bool whatsappSent;

  factory DriverImportRow.fromJson(Map<String, dynamic> json) {
    return DriverImportRow(
      row: asInt(json['row']) ?? 0,
      name: asString(json['name']) ?? '',
      phone: asString(json['phone']),
      inviteUrl: asString(json['invite_url']) ?? '',
      whatsappSent: asBool(json['whatsapp_sent']),
    );
  }
}

class DriverImportError {
  const DriverImportError({
    required this.row,
    required this.field,
    required this.message,
    this.name,
    this.phone,
    this.email,
    this.licenseNumber,
  });

  final int row;
  final String field;
  final String message;
  final String? name;
  final String? phone;
  final String? email;
  final String? licenseNumber;

  String get details {
    return [
      if (name != null && name!.trim().isNotEmpty) name!.trim(),
      if (phone != null && phone!.trim().isNotEmpty) phone!.trim(),
      if (email != null && email!.trim().isNotEmpty) email!.trim(),
      if (licenseNumber != null && licenseNumber!.trim().isNotEmpty) licenseNumber!.trim(),
    ].join(' · ');
  }

  factory DriverImportError.fromJson(Map<String, dynamic> json) {
    return DriverImportError(
      row: asInt(json['row']) ?? 0,
      field: asString(json['field']) ?? '',
      message: asString(json['message']) ?? '',
      name: asString(json['name']),
      phone: asString(json['phone']),
      email: asString(json['email']),
      licenseNumber: asString(json['license_number']),
    );
  }
}

class DriverImportResult {
  const DriverImportResult({
    required this.created,
    required this.failed,
    required this.invitesSent,
    required this.drivers,
    required this.errors,
  });

  final int created;
  final int failed;
  final int invitesSent;
  final List<DriverImportRow> drivers;
  final List<DriverImportError> errors;

  factory DriverImportResult.fromJson(Map<String, dynamic> json) {
    return DriverImportResult(
      created: asInt(json['created']) ?? 0,
      failed: asInt(json['failed']) ?? 0,
      invitesSent: asInt(json['invites_sent']) ?? 0,
      drivers: (json['drivers'] as List? ?? [])
          .whereType<Map>()
          .map((item) => DriverImportRow.fromJson(asMap(item)))
          .toList(),
      errors: (json['errors'] as List? ?? [])
          .whereType<Map>()
          .map((item) => DriverImportError.fromJson(asMap(item)))
          .toList(),
    );
  }
}
