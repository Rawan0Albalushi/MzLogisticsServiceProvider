import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/trip.dart';

class TripRepository {
  TripRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Trip>> list({
    int page = 1,
    int perPage = 15,
    String? status,
    int? jobId,
  }) async {
    final response = await _api.get(ApiEndpoints.trips, query: {
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      'job_id': ?jobId,
    });
    return Paginated.fromResponse(response, Trip.fromJson);
  }

  Future<Trip> show(int id) async {
    final response = await _api.get(ApiEndpoints.trip(id));
    return Trip.fromJson(asMap(response['data']));
  }

  Future<Trip> assign(int id, {required int truckId, required int driverId}) async {
    final response = await _api.post(ApiEndpoints.assignTrip(id), data: {
      'truck_id': truckId,
      'driver_id': driverId,
    });
    return Trip.fromJson(asMap(response['data']));
  }

  Future<Trip> updateStatus(int id, String status) async {
    final response = await _api.post(ApiEndpoints.tripStatus(id), data: {
      'status': status,
    });
    return Trip.fromJson(asMap(response['data']));
  }
}
