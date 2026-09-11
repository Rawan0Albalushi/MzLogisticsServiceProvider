import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/truck_type.dart';

class TruckTypeRepository {
  TruckTypeRepository(this._api);

  final ApiClient _api;

  Future<List<TruckTypeOption>> catalog() async {
    final response = await _api.get(ApiEndpoints.catalog);
    final types = asMapList(asMap(response['data'])['truck_types']);
    if (types.isEmpty) {
      return AppConfig.truckTypes.map(TruckTypeOption.fallback).toList();
    }
    return types.map(TruckTypeOption.fromJson).where((item) => item.code.isNotEmpty).toList();
  }

  Future<List<TruckTypeOption>> all() async {
    final response = await _api.get(ApiEndpoints.truckTypes);
    return asMapList(response['data']).map(TruckTypeOption.fromJson).where((item) => item.code.isNotEmpty).toList();
  }

  Future<TruckTypeOption> create(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.truckTypes, data: payload);
    return TruckTypeOption.fromJson(asMap(response['data']));
  }

  Future<TruckTypeOption> update(int id, Map<String, dynamic> payload) async {
    final response = await _api.patch(ApiEndpoints.truckType(id), data: payload);
    return TruckTypeOption.fromJson(asMap(response['data']));
  }

  Future<void> delete(int id) async {
    await _api.delete(ApiEndpoints.truckType(id));
  }
}
