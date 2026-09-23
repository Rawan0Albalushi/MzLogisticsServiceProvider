import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/document.dart';
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

  Future<CompanyDocument> uploadDocument({
    required int organizationId,
    required String type,
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.post(
      ApiEndpoints.organizationDocuments(organizationId),
      data: FormData.fromMap({
        'type': type,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return CompanyDocument.fromJson(asMap(response['data']));
  }

  Future<Organization> update(int id, Map<String, dynamic> payload) async {
    final response = await _api.patch(ApiEndpoints.organization(id), data: payload);
    return Organization.fromJson(asMap(response['data']));
  }
}
