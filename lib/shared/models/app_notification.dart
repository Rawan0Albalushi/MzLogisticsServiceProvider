import '../../core/utils/json_utils.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    this.type,
    this.title,
    this.body,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String? type;
  final String? title;
  final String? body;
  final String? readAt;
  final String? createdAt;

  bool get isUnread => readAt == null || readAt!.isEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = asMap(json['data']);
    return AppNotification(
      id: asString(json['id']) ?? '',
      type: asString(json['type']),
      title: asString(data['title']) ?? asString(json['title']) ?? asString(json['type']),
      body: asString(data['body']) ?? asString(data['message']) ?? asString(json['message']),
      readAt: asString(json['read_at']),
      createdAt: asString(json['created_at']),
    );
  }
}
