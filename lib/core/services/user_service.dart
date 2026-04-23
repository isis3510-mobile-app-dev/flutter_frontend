import 'dart:async';
import 'dart:convert';

import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import 'local_database_service.dart';
import 'response_cache_service.dart';

class UserService {
  UserService._();

  static final UserService _instance = UserService._();

  factory UserService() => _instance;

  static const String currentUserPath = '/api/users/me/';
  static const String _currentUserCacheKey = 'users.current';
  static const Duration _currentUserCacheTtl = Duration(minutes: 5);
  static const String _entityTypeUser = 'user';
  static const String _actionUpdateProfile = 'update_profile';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<UserProfile> getCurrentUser({bool forceRefresh = false}) async {
    final cachedEntry = await _cache.get(_currentUserCacheKey);
    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_currentUserCacheTtl)) {
      final cachedProfile = _tryParseCurrentUser(cachedEntry.body);
      if (cachedProfile != null) {
        unawaited(_persistCurrentUserFromBody(cachedEntry.body));
        return cachedProfile;
      }
    }

    try {
      final response = await _apiClient.get(currentUserPath);
      final profile = _parseCurrentUser(response.body);
      await _cache.set(_currentUserCacheKey, response.body);
      await _persistCurrentUserFromBody(response.body);
      return profile;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackProfile = _tryParseCurrentUser(cachedEntry.body);
        if (fallbackProfile != null) {
          unawaited(_persistCurrentUserFromBody(cachedEntry.body));
          return fallbackProfile;
        }
      }

      final localProfile = await _getCurrentUserFromLocalDb();
      if (localProfile != null) {
        return localProfile;
      }
      rethrow;
    }
  }

  Future<UserProfile> updateCurrentUser({
    required String name,
    String phone = '',
    String address = '',
    String profilePhoto = '',
  }) async {
    final updatePayload = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      'profilePhoto': profilePhoto,
      'initials': _initialsFromName(name),
    };

    try {
      final response = await _apiClient.put(
        currentUserPath,
        body: updatePayload,
      );

      if (response.body.isEmpty) {
        await _cache.clear(_currentUserCacheKey);
        return getCurrentUser(forceRefresh: true);
      }

      final profile = _parseCurrentUser(response.body);
      await _cache.set(_currentUserCacheKey, response.body);
      await _persistCurrentUserFromBody(response.body);
      return profile;
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final localProfileJson = await _getCurrentUserJsonFromLocalDb();
      if (localProfileJson == null) {
        rethrow;
      }

      final userId = (localProfileJson['id'] as String?)?.trim() ?? '';
      if (userId.isEmpty) {
        rethrow;
      }

      final mergedProfile = <String, dynamic>{
        ...localProfileJson,
        ...updatePayload,
      };

      await _localDb.upsertEntity(
        table: LocalDbTables.users,
        remoteId: userId,
        payload: mergedProfile,
        syncStatus: 'pending_update',
      );

      await _localDb.enqueueSyncOperation(
        entityType: _entityTypeUser,
        entityId: userId,
        action: _actionUpdateProfile,
        payload: updatePayload,
      );

      await _cache.set(_currentUserCacheKey, jsonEncode(mergedProfile));
      return UserProfile.fromJson(mergedProfile);
    }
  }

  Future<void> retryPendingSyncOperations({int limit = 30}) async {
    final operations = await _localDb.getPendingSyncOperations(
      entityType: _entityTypeUser,
      limit: limit,
    );

    for (final operation in operations) {
      try {
        switch (operation.action) {
          case _actionUpdateProfile:
            final response = await _apiClient.put(
              currentUserPath,
              body: operation.payload ?? const <String, dynamic>{},
            );

            if (response.body.trim().isNotEmpty) {
              await _persistCurrentUserFromBody(response.body);
              await _cache.set(_currentUserCacheKey, response.body);
            } else {
              await _cache.clear(_currentUserCacheKey);
            }
            break;
          default:
            break;
        }

        await _localDb.markSyncOperationCompleted(operation.id);
      } catch (error) {
        await _localDb.markSyncOperationFailed(
          operation.id,
          error: error.toString(),
        );
      }
    }
  }

  UserProfile _parseCurrentUser(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected current user response from server.',
      );
    }

    return UserProfile.fromJson(json);
  }

  UserProfile? _tryParseCurrentUser(String body) {
    try {
      return _parseCurrentUser(body);
    } catch (_) {
      return null;
    }
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

  Future<void> _persistCurrentUserFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final remoteId = decoded['id'];
      if (remoteId is! String || remoteId.trim().isEmpty) {
        return;
      }

      await _localDb.upsertEntity(
        table: LocalDbTables.users,
        remoteId: remoteId.trim(),
        payload: decoded,
      );
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<UserProfile?> _getCurrentUserFromLocalDb() async {
    try {
      final userJson = await _getCurrentUserJsonFromLocalDb();
      if (userJson == null) {
        return null;
      }

      return UserProfile.fromJson(userJson);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getCurrentUserJsonFromLocalDb() async {
    try {
      final users = await _localDb.getAllEntities(LocalDbTables.users);
      if (users.isEmpty) {
        return null;
      }

      return users.first;
    } catch (_) {
      return null;
    }
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }
}
