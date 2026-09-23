import '../../core/permissions/app_permissions.dart';
import '../../core/utils/json_utils.dart';
import 'document.dart';
import 'organization.dart';

class DriverProfile {
  const DriverProfile({
    this.id,
    this.licenseNumber,
    this.licenseExpiresAt,
    this.status,
  });

  final int? id;
  final String? licenseNumber;
  final String? licenseExpiresAt;
  final String? status;

  bool get isAvailable => status == 'available';
  bool get isInactive => status == 'inactive';
  bool get isOnTrip => status == 'on_trip';

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: asInt(json['id']),
      licenseNumber: asString(json['license_number']),
      licenseExpiresAt: asString(json['license_expires_at']),
      status: asString(json['status']),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.locale,
    this.userType,
    this.isActive = true,
    this.organizationId,
    this.organization,
    this.roles = const [],
    this.roleLabels = const [],
    this.permissions = const [],
    this.driverProfile,
    this.documents = const [],
    this.lastLoginAt,
    this.mustSetPassword = false,
  });

  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? locale;
  final String? userType;
  final bool isActive;
  final int? organizationId;
  final Organization? organization;
  final List<String> roles;
  final List<String> roleLabels;
  final List<String> permissions;
  final DriverProfile? driverProfile;
  final List<CompanyDocument> documents;
  final String? lastLoginAt;
  final bool mustSetPassword;

  String? get displayStatus => mustSetPassword ? 'pending_activation' : driverProfile?.status;

  PermissionSet get permissionSet => PermissionSet(permissions);

  bool can(String permission) => permissionSet.can(permission);

  String get primaryRole => roles.isEmpty ? '—' : roles.first;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asString(json['phone']),
      locale: asString(json['locale']),
      userType: asString(json['user_type']),
      isActive: asBool(json['is_active'], fallback: true),
      organizationId: asInt(json['organization_id']),
      organization: json['organization'] is Map
          ? Organization.fromJson(asMap(json['organization']))
          : null,
      roles: asStringList(json['roles']),
      roleLabels: asStringList(json['role_labels']),
      permissions: asStringList(json['permissions']),
      driverProfile: json['driver_profile'] is Map
          ? DriverProfile.fromJson(asMap(json['driver_profile']))
          : null,
      documents: asMapList(json['documents']).map(CompanyDocument.fromJson).toList(),
      lastLoginAt: asString(json['last_login_at']),
      mustSetPassword: asBool(json['must_set_password']),
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? locale,
    Organization? organization,
    List<String>? permissions,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      locale: locale ?? this.locale,
      userType: userType,
      isActive: isActive,
      organizationId: organizationId,
      organization: organization ?? this.organization,
      roles: roles,
      roleLabels: roleLabels,
      permissions: permissions ?? this.permissions,
      driverProfile: driverProfile,
      documents: documents,
      lastLoginAt: lastLoginAt,
      mustSetPassword: mustSetPassword,
    );
  }
}
