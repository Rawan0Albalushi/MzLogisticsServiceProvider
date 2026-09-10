import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paginated.dart';
import '../../../shared/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<Paginated<AppNotification>> list({int page = 1}) async {
    final response = await _api.get(ApiEndpoints.notifications, query: {
      'page': page,
      'per_page': 20,
    });
    return Paginated.fromResponse(response, AppNotification.fromJson);
  }

  Future<void> markRead(String id) {
    return _api.post(ApiEndpoints.readNotification(id));
  }

  Future<void> markAllRead() {
    return _api.post(ApiEndpoints.readAllNotifications);
  }
}
