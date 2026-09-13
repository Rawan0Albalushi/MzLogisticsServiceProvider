import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/models/user.dart';

class FleetRepository {
  FleetRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Truck>> trucks({int page = 1, int perPage = 15, String? status, String? search}) async {
    final response = await _api.get(ApiEndpoints.trucks, query: {
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return Paginated.fromResponse(response, Truck.fromJson);
  }

  Future<Truck> createTruck(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.trucks, data: payload);
    return Truck.fromJson(asMap(response['data']));
  }

  Future<Truck> updateTruck(int id, Map<String, dynamic> payload) async {
    final response = await _api.put(ApiEndpoints.truck(id), data: payload);
    return Truck.fromJson(asMap(response['data']));
  }

  Future<Paginated<EquipmentItem>> equipment({int page = 1, String? status, String? search}) async {
    final response = await _api.get(ApiEndpoints.equipment, query: {
      'page': page,
      'per_page': 15,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return Paginated.fromResponse(response, EquipmentItem.fromJson);
  }

  Future<EquipmentItem> createEquipment(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.equipment, data: payload);
    return EquipmentItem.fromJson(asMap(response['data']));
  }

  Future<Paginated<AppUser>> drivers({int page = 1, int perPage = 15, String? search, String? status}) async {
    final response = await _api.get(ApiEndpoints.drivers, query: {
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return Paginated.fromResponse(response, AppUser.fromJson);
  }

  Future<AppUser> createDriver(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.drivers, data: payload);
    return AppUser.fromJson(asMap(response['data']));
  }
}
