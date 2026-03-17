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

  Future<UserProfile> updateCurrentUser({
    required String name,
    required String email,
    String phone = '',
    String address = '',
    String profilePhoto = '',
  }) async {
    final response = await _apiClient.put(
      currentUserPath,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'profilePhoto': profilePhoto,
        'initials': _initialsFromName(name),
      },
    );

    if (response.body.isEmpty) {
      return getCurrentUser();
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(json);
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    final first = parts.first[0].toUpperCase();
    if (parts.length == 1) {
      return first;
    }

    return '$first${parts.last[0].toUpperCase()}';
  }
}
