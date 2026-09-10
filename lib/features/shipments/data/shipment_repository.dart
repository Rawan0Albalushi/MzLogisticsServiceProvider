import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/shipment.dart';

class ShipmentRepository {
  ShipmentRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Shipment>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final response = await _api.get(ApiEndpoints.shipments, query: {
      'page': page,
      'per_page': 15,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return Paginated.fromResponse(response, Shipment.fromJson);
  }

  Future<Shipment> show(int id) async {
    final response = await _api.get(ApiEndpoints.shipment(id));
    return Shipment.fromJson(asMap(response['data']));
  }
}
