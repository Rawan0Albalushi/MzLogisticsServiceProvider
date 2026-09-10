import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardSnapshot> fetch() async {
    final response = await _api.get(ApiEndpoints.dashboard);
    return DashboardSnapshot.fromJson(asMap(response['data']));
  }
}
