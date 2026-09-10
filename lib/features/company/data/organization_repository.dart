import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/organization.dart';

class OrganizationRepository {
  OrganizationRepository(this._api);

  final ApiClient _api;

  Future<Organization> show(int id) async {
    final response = await _api.get(ApiEndpoints.organization(id));
    final data = asMap(response['data']);
    final merged = {
      ...data,
      if (response['users'] != null) 'users': response['users'],
      if (response['trucks'] != null) 'trucks': response['trucks'],
      if (response['documents'] != null) 'documents': response['documents'],
    };
    return Organization.fromJson(merged);
  }

  Future<Organization> update(int id, Map<String, dynamic> payload) async {
    final response = await _api.patch(ApiEndpoints.organization(id), data: payload);
    return Organization.fromJson(asMap(response['data']));
  }
}
