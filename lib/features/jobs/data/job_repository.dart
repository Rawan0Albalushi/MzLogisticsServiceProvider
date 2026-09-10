import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/job.dart';

class JobRepository {
  JobRepository(this._api);

  final ApiClient _api;

  Future<Paginated<TransportJob>> list({int page = 1, String? status}) async {
    final response = await _api.get(ApiEndpoints.jobs, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return Paginated.fromResponse(response, TransportJob.fromJson);
  }

  Future<TransportJob> show(int id) async {
    final response = await _api.get(ApiEndpoints.job(id));
    return TransportJob.fromJson(asMap(response['data']));
  }
}
