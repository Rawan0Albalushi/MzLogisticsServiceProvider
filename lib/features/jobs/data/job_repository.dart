import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/job.dart';

class JobRepository {
  JobRepository(this._api);

  final ApiClient _api;

  Future<Paginated<TransportJob>> list({
    int page = 1,
    String? status,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.jobs, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, TransportJob.fromJson);
  }

  Future<TransportJob> show(int id) async {
    final response = await _api.get(ApiEndpoints.job(id));
    return TransportJob.fromJson(asMap(response['data']));
  }
}
