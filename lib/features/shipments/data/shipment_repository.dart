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
    String? city,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _api.get(ApiEndpoints.shipments, query: {
      'page': page,
      'per_page': 15,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (city != null && city.isNotEmpty) 'city': city,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    });
    return Paginated.fromResponse(response, Shipment.fromJson);
  }

  Future<Shipment> show(int id) async {
    final response = await _api.get(ApiEndpoints.shipment(id));
    return Shipment.fromJson(asMap(response['data']));
  }
}
