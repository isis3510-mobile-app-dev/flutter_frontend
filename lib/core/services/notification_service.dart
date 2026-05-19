import 'dart:convert';

import '../models/notification_model.dart';
import '../network/api_client.dart';
import 'user_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  final ApiClient _apiClient = ApiClient();
  final UserService _userService = UserService();

  Future<List<NotificationModel>> getMyNotifications() async {
    final user = await _userService.getCurrentUser();
    final userId = Uri.encodeComponent(user.id);
    final response = await _apiClient.get(
      '/api/notifications/?user_id=$userId',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <NotificationModel>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(NotificationModel.fromJson)
        .toList(growable: false);
  }
}
