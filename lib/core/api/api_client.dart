import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../utils/json_utils.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this._tokenStorage,
    required this._onUnauthorized,
    Dio? dio,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
            _onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function() _onUnauthorized;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) {
    return _send(() => _dio.post<dynamic>(path, data: data, queryParameters: query));
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
  }) {
    return _send(() => _dio.put<dynamic>(path, data: data));
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
  }) {
    return _send(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return asMap(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(message: 'network');
    }

    final payload = asMap(error.response?.data);
    final errors = <String, List<String>>{};
    final rawErrors = payload['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          errors[key.toString()] = value.map((item) => item.toString()).toList();
        } else if (value != null) {
          errors[key.toString()] = [value.toString()];
        }
      });
    }

    return ApiException(
      message: asString(payload['message']) ?? 'error',
      statusCode: error.response?.statusCode,
      fieldErrors: errors,
    );
  }
}
