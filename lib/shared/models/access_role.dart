import '../../core/utils/json_utils.dart';
import '../../core/permissions/app_permissions.dart';

class AccessRole {
  const AccessRole({
    required this.name,
    required this.displayName,
    this.id,
    this.usersCount = 0,
    this.permissions = const [],
    this.isSystem = true,
    this.canManage = false,
    this.canDelete = false,
  });

  final int? id;
  final String name;
  final String displayName;
  final int usersCount;
  final List<String> permissions;
  final bool isSystem;
  final bool canManage;
  final bool canDelete;

  bool grants(String permission) => permissions.contains(permission);

  int grantedIn(PermissionGroup group) => group.keys.where(grants).length;

  bool matches(Iterable<String> roles) {
    return roles.any((role) => role.trim() == name);
  }

  ProviderRoleGuide? get guide {
    for (final item in AppPermissions.roleGuides) {
      if (item.backendName == name) {
        return item;
      }
    }
    return null;
  }

  factory AccessRole.fromJson(Map<String, dynamic> json) {
    return AccessRole(
      id: asInt(json['id']),
      name: asString(json['name']) ?? '',
      displayName: asString(json['display_name']) ?? asString(json['name']) ?? '',
      usersCount: asInt(json['users_count']) ?? 0,
      permissions: asStringList(json['permissions']),
      isSystem: asBool(json['is_system'], fallback: true),
      canManage: asBool(json['can_manage']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class AccessCatalog {
  const AccessCatalog({
    this.roles = const [],
    this.permissions = const [],
    this.assignableRoles = const [],
  });

  final List<AccessRole> roles;
  final List<String> permissions;
  final List<String> assignableRoles;

  factory AccessCatalog.fromJson(Map<String, dynamic> json) {
    return AccessCatalog(
      roles: asMapList(json['roles']).map(AccessRole.fromJson).where((role) => role.name.isNotEmpty).toList(),
      permissions: asStringList(json['permissions']),
      assignableRoles: asStringList(json['assignable_roles']).isNotEmpty
          ? asStringList(json['assignable_roles'])
          : asStringList(json['platform_roles']),
    );
  }
}
