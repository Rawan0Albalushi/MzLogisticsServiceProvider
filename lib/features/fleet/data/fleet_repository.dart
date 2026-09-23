import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/driver_invite.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/models/fleet_import.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/models/user.dart';

class FleetRepository {
  FleetRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Truck>> trucks({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
  }) async {
    final response = await _api.get(
      ApiEndpoints.trucks,
      query: {
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return Paginated.fromResponse(response, Truck.fromJson);
  }

  Future<Truck> createTruck(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.trucks, data: payload);
    return Truck.fromJson(asMap(response['data']));
  }

  Future<List<int>> downloadTruckImportTemplate() {
    return _api.getBytes(ApiEndpoints.trucksImportTemplate);
  }

  Future<FleetImportResult> importTrucks({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.post(
      ApiEndpoints.trucksImport,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return FleetImportResult.fromJson(
      asMap(response['data']),
      errorDetailKeys: const ['plate_number', 'type'],
    );
  }

  Future<Truck> updateTruck(int id, Map<String, dynamic> payload) async {
    final response = await _api.put(ApiEndpoints.truck(id), data: payload);
    return Truck.fromJson(asMap(response['data']));
  }

  Future<Paginated<EquipmentItem>> equipment({
    int page = 1,
    String? status,
    String? search,
    String? placement,
  }) async {
    final response = await _api.get(
      ApiEndpoints.equipment,
      query: {
        'page': page,
        'per_page': 15,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (placement != null && placement.isNotEmpty) 'placement': placement,
      },
    );
    return Paginated.fromResponse(response, EquipmentItem.fromJson);
  }

  Future<List<int>> downloadEquipmentImportTemplate() {
    return _api.getBytes(ApiEndpoints.equipmentImportTemplate);
  }

  Future<FleetImportResult> importEquipment({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.post(
      ApiEndpoints.equipmentImport,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return FleetImportResult.fromJson(
      asMap(response['data']),
      errorDetailKeys: const ['name', 'truck_plate'],
    );
  }

  Future<EquipmentItem> createEquipment(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.equipment, data: payload);
    return EquipmentItem.fromJson(asMap(response['data']));
  }

  Future<EquipmentItem> updateEquipment(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.put(
      ApiEndpoints.equipmentItem(id),
      data: payload,
    );
    return EquipmentItem.fromJson(asMap(response['data']));
  }

  Future<Paginated<AppUser>> drivers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
  }) async {
    final response = await _api.get(
      ApiEndpoints.drivers,
      query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return Paginated.fromResponse(response, AppUser.fromJson);
  }

  Future<DriverInviteResult> createDriver(Map<String, dynamic> payload) async {
    final response = await _api.post(ApiEndpoints.drivers, data: payload);
    return DriverInviteResult.fromJson(asMap(response['data']));
  }

  Future<AppUser> updateDriver(int id, Map<String, dynamic> payload) async {
    final response = await _api.put(ApiEndpoints.driver(id), data: payload);
    return AppUser.fromJson(asMap(response['data']));
  }

  Future<List<int>> downloadDriverImportTemplate() {
    return _api.getBytes(ApiEndpoints.driversImportTemplate);
  }

  Future<DriverImportResult> importDrivers({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.post(
      ApiEndpoints.driversImport,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return DriverImportResult.fromJson(asMap(response['data']));
  }

  Future<DriverInviteResult> resendDriverInvite(int driverId) async {
    final response = await _api.post(ApiEndpoints.resendDriverInvite(driverId));
    return DriverInviteResult.fromJson(asMap(response['data']));
  }
}
