import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/access_role.dart';

class RoleRepository {
  RoleRepository(this._api);

  final ApiClient _api;

  Future<AccessCatalog> catalog() async {
    final response = await _api.get(ApiEndpoints.roles);
    return AccessCatalog.fromJson(asMap(response['data']));
  }

  Future<AccessRole> create({required String name, required List<String> permissions}) async {
    final response = await _api.post(
      ApiEndpoints.roles,
      data: {'name': name, 'permissions': permissions},
    );
    return AccessRole.fromJson(asMap(response['data']));
  }

  Future<AccessRole> update({
    required String role,
    required List<String> permissions,
    String? name,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.role(role),
      data: {
        'permissions': permissions,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );
    return AccessRole.fromJson(asMap(response['data']));
  }

  Future<void> delete(String role) async {
    await _api.delete(ApiEndpoints.role(role));
  }
}
