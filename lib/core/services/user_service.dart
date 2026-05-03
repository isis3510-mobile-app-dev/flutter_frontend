import 'dart:async';
import 'dart:convert';

import 'package:flutter_frontend/core/models/user_profile.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import 'attachment_upload_service.dart';
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
  static const String _profilePhotoKey = 'profilePhoto';
  static const String _profilePhotoPendingUploadKey =
      'profilePhotoPendingUpload';
  static const String _profilePhotoStoragePathKey = 'profilePhotoStoragePath';
  static const String _profilePhotoLocalFilePathKey =
      'profilePhotoLocalFilePath';
  static const String _profilePhotoFileNameKey = 'profilePhotoFileName';
  static const String _profilePhotoContentTypeKey = 'profilePhotoContentType';
  static const String _profilePhotoSizeBytesKey = 'profilePhotoSizeBytes';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();

  Future<UserProfile> getCurrentUser({bool forceRefresh = false}) async {
    final cachedEntry = await _cache.get(_currentUserCacheKey);
    if (!forceRefresh &&
        cachedEntry != null &&
        cachedEntry.isFresh(_currentUserCacheTtl)) {
      final cachedProfile = _tryParseCurrentUser(cachedEntry.body);
      if (cachedProfile != null) {
        final pendingLocalProfile = await _getPendingCurrentUserFromLocalDb(
          remoteId: cachedProfile.id,
        );
        if (pendingLocalProfile != null) {
          return pendingLocalProfile;
        }
        unawaited(_persistCurrentUserFromBody(cachedEntry.body));
        return cachedProfile;
      }
    }

    try {
      final response = await _apiClient.get(currentUserPath);
      final profile = _parseCurrentUser(response.body);
      final pendingLocalProfile = await _getPendingCurrentUserFromLocalDb(
        remoteId: profile.id,
      );
      if (pendingLocalProfile != null) {
        await _persistCurrentUserFromBody(response.body);
        return pendingLocalProfile;
      }

      await _cache.set(_currentUserCacheKey, response.body);
      await _persistCurrentUserFromBody(response.body);
      return profile;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackProfile = _tryParseCurrentUser(cachedEntry.body);
        if (fallbackProfile != null) {
          final pendingLocalProfile = await _getPendingCurrentUserFromLocalDb(
            remoteId: fallbackProfile.id,
          );
          if (pendingLocalProfile != null) {
            return pendingLocalProfile;
          }
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
    Map<String, dynamic> profilePhotoSyncPayload = const <String, dynamic>{},
  }) async {
    final updatePayload = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      _profilePhotoKey: profilePhoto,
      'initials': _initialsFromName(name),
      ...profilePhotoSyncPayload,
    };

    try {
      final apiPayload = await _prepareUserUpdatePayloadForApi(updatePayload);
      final response = await _apiClient.put(currentUserPath, body: apiPayload);

      if (response.body.isEmpty) {
        await _cache.clear(_currentUserCacheKey);
        return getCurrentUser(forceRefresh: true);
      }

      final profile = _parseCurrentUser(response.body);
      await _cache.set(_currentUserCacheKey, response.body);
      await _persistCurrentUserFromBody(
        response.body,
        preservePendingLocal: false,
      );
      return profile;
    } catch (error) {
      if (!_shouldQueueOffline(error) &&
          !_shouldQueuePendingProfilePhotoResolution(error, updatePayload)) {
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
            final updatePayload =
                operation.payload ?? const <String, dynamic>{};
            final apiPayload = await _prepareUserUpdatePayloadForApi(
              updatePayload,
            );
            final response = await _apiClient.put(
              currentUserPath,
              body: apiPayload,
            );

            if (response.body.trim().isNotEmpty) {
              await _persistCurrentUserFromBody(
                response.body,
                preservePendingLocal: false,
              );
              await _cache.set(_currentUserCacheKey, response.body);
            } else {
              await _persistSuccessfulUserUpdatePayload(
                userId: operation.entityId,
                payload: apiPayload,
              );
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

  Future<bool> _persistCurrentUserFromBody(
    String body, {
    bool preservePendingLocal = true,
  }) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final remoteId = decoded['id'];
      if (remoteId is! String || remoteId.trim().isEmpty) {
        return false;
      }

      final normalizedRemoteId = remoteId.trim();
      if (preservePendingLocal) {
        final syncStatus = await _localDb.getEntitySyncStatus(
          table: LocalDbTables.users,
          remoteId: normalizedRemoteId,
        );
        if (_isPendingSyncStatus(syncStatus)) {
          return false;
        }
      }

      await _localDb.upsertEntity(
        table: LocalDbTables.users,
        remoteId: normalizedRemoteId,
        payload: decoded,
      );
      return true;
    } catch (_) {
      // Local persistence is best effort.
      return false;
    }
  }

  Future<void> _persistSuccessfulUserUpdatePayload({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final localProfileJson = await _getCurrentUserJsonFromLocalDb();
    final mergedProfile = <String, dynamic>{
      if (localProfileJson != null) ...localProfileJson,
      ...payload,
      'id': normalizedUserId,
    };

    await _localDb.upsertEntity(
      table: LocalDbTables.users,
      remoteId: normalizedUserId,
      payload: mergedProfile,
    );
    await _cache.set(_currentUserCacheKey, jsonEncode(mergedProfile));
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

  Future<UserProfile?> _getPendingCurrentUserFromLocalDb({
    String? remoteId,
  }) async {
    final userJson = await _getCurrentUserJsonFromLocalDb();
    if (userJson == null) {
      return null;
    }

    final userId = (userJson['id'] as String?)?.trim() ?? '';
    if (userId.isEmpty) {
      return null;
    }

    final normalizedRemoteId = remoteId?.trim() ?? '';
    if (normalizedRemoteId.isNotEmpty && normalizedRemoteId != userId) {
      return null;
    }

    final syncStatus = await _localDb.getEntitySyncStatus(
      table: LocalDbTables.users,
      remoteId: userId,
    );
    if (!_isPendingSyncStatus(syncStatus)) {
      return null;
    }

    try {
      return UserProfile.fromJson(userJson);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _prepareUserUpdatePayloadForApi(
    Map<String, dynamic> payload,
  ) async {
    final prepared = <String, dynamic>{...payload};
    if (_hasPendingProfilePhotoUpload(prepared)) {
      final resolvedPhotoUrl = await _attachmentUploadService
          .resolvePendingUploadUrl(
            storagePath:
                (prepared[_profilePhotoStoragePathKey] as String?)?.trim() ??
                '',
            localFilePath:
                (prepared[_profilePhotoLocalFilePathKey] as String?)?.trim() ??
                '',
            fileName:
                (prepared[_profilePhotoFileNameKey] as String?)?.trim() ?? '',
            contentType:
                (prepared[_profilePhotoContentTypeKey] as String?)?.trim() ??
                '',
          );
      prepared[_profilePhotoKey] = resolvedPhotoUrl;
    }

    for (final key in _localProfilePhotoSyncKeys) {
      prepared.remove(key);
    }
    return prepared;
  }

  bool _hasPendingProfilePhotoUpload(Map<String, dynamic> payload) {
    final isPending = payload[_profilePhotoPendingUploadKey] == true;
    final storagePath =
        (payload[_profilePhotoStoragePathKey] as String?)?.trim() ?? '';
    final profilePhoto = (payload[_profilePhotoKey] as String?)?.trim() ?? '';
    return isPending || (profilePhoto.isEmpty && storagePath.isNotEmpty);
  }

  List<String> get _localProfilePhotoSyncKeys => const <String>[
    _profilePhotoPendingUploadKey,
    _profilePhotoStoragePathKey,
    _profilePhotoLocalFilePathKey,
    _profilePhotoFileNameKey,
    _profilePhotoContentTypeKey,
    _profilePhotoSizeBytesKey,
  ];

  bool _isPendingSyncStatus(String? syncStatus) {
    return syncStatus != null && syncStatus.startsWith('pending_');
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }

  bool _shouldQueuePendingProfilePhotoResolution(
    Object error,
    Map<String, dynamic> payload,
  ) {
    final message = error.toString();
    return message.contains('Attachment upload still pending') &&
        _hasPendingProfilePhotoUpload(payload);
  }
}
