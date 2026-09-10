import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/json_utils.dart';
import '../../../shared/models/user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> login(String email, String password) async {
    final response = await _api.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return _sessionFrom(response);
  }

  Future<AuthSession> registerProvider({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String companyName,
    String? commercialRegister,
    String? phone,
    String? city,
    String? locale,
  }) async {
    final response = await _api.post(ApiEndpoints.registerProvider, data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'company_name': companyName,
      if (commercialRegister != null && commercialRegister.isNotEmpty)
        'commercial_register': commercialRegister,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (city != null && city.isNotEmpty) 'city': city,
      'locale': ?locale,
    });
    return _sessionFrom(response);
  }

  Future<AppUser> me() async {
    final response = await _api.get(ApiEndpoints.me);
    return AppUser.fromJson(asMap(response['data']));
  }

  Future<AppUser> updateMe({String? name, String? phone, String? locale}) async {
    final response = await _api.patch(ApiEndpoints.me, data: {
      'name': ?name,
      'phone': ?phone,
      'locale': ?locale,
    });
    return AppUser.fromJson(asMap(response['data']));
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Token is cleared locally regardless of network result.
    }
  }

  AuthSession _sessionFrom(Map<String, dynamic> response) {
    final data = asMap(response['data']);
    return AuthSession(
      token: asString(data['token']) ?? '',
      user: AppUser.fromJson(asMap(data['user'])),
    );
  }
}
