import 'dart:convert';

import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_client.dart';

class UserService {
  UserService._();

  static final UserService _instance = UserService._();

  factory UserService() => _instance;

  static const String currentUserPath = '/api/users/me/';

  final ApiClient _apiClient = ApiClient();

  Future<UserProfile> getCurrentUser() async {
    final response = await _apiClient.get(currentUserPath);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }
}
