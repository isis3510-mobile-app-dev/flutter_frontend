import 'dart:async';
import 'dart:convert';

import '../models/lost_pet_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'local_database_service.dart';
import 'response_cache_service.dart';

class LostPetService {
  LostPetService._();

  static final LostPetService _instance = LostPetService._();

  factory LostPetService() => _instance;

  static const String lostPetsPath = '/api/lost-pets/';
  static const String _lostPetsCacheKey = 'lost_pets.public';

  static const String _entityTypeLostPetReport = 'lost_pet_report';
  static const String _actionCreateReport = 'create_report';
  static const String _actionUpdateReport = 'update_report';
  static const String _actionResolveReport = 'resolve_report';
  static const String _petIdMappingMetaPrefix = 'pet_id_map.';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<List<LostPetReportModel>> getLostPets({
    bool forceRefresh = false,
  }) async {
    final cachedEntry = await _cache.get(_lostPetsCacheKey);

    try {
      final response = await _apiClient.get(lostPetsPath, authenticated: false);
      final reports = _parseReports(response.body);
      await _cache.set(_lostPetsCacheKey, response.body);
      await _persistReportsFromBody(response.body);
      return reports;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackReports = _tryParseReports(cachedEntry.body);
        if (fallbackReports != null) {
          unawaited(_persistReportsFromBody(cachedEntry.body));
          return fallbackReports;
        }
      }

      final localReports = await _getReportsFromLocalDb();
      if (localReports.isNotEmpty) {
        return localReports;
      }
      rethrow;
    }
  }

  Future<LostPetReportModel> getLostPetDetail(String reportId) async {
    final trimmedReportId = reportId.trim();

    try {
      final response = await _apiClient.get(
        '$lostPetsPath$trimmedReportId/',
        authenticated: false,
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected lost pet detail response from server.',
        );
      }

      await _persistReportMap(_asMap(decoded));
      return LostPetReportModel.fromJson(decoded);
    } on ApiException catch (error) {
      if (error.type != ApiErrorType.network) {
        rethrow;
      }

      final localReport = await _localDb.getEntityById(
        table: LocalDbTables.lostPets,
        remoteId: trimmedReportId,
      );
      if (localReport != null &&
          (localReport['status'] as String?) == 'active') {
        return LostPetReportModel.fromJson(localReport);
      }
      rethrow;
    }
  }

  Future<LostPetReportModel?> getOwnerLostReport(String petId) async {
    final normalizedPetId = petId.trim();
    try {
      final response = await _apiClient.get(
        '/api/pets/$normalizedPetId/lost-report/',
      );
      if (response.body.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      await _persistReportMap(_asMap(decoded));
      return LostPetReportModel.fromJson(decoded);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<LostPetReportModel> saveOwnerLostReport({
    required String petId,
    required Map<String, dynamic> data,
    bool isUpdate = false,
  }) async {
    final normalizedPetId = petId.trim();
    try {
      final response = isUpdate
          ? await _apiClient.put(
              '/api/pets/$normalizedPetId/lost-report/',
              body: data,
            )
          : await _apiClient.post(
              '/api/pets/$normalizedPetId/lost-report/',
              body: data,
            );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected lost report response from server.',
        );
      }
      await _persistReportMap(_asMap(decoded));
      await _markLocalPetStatus(normalizedPetId, 'lost');
      await _invalidateLostPetsCache();
      await _invalidatePetCaches();
      return LostPetReportModel.fromJson(decoded);
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final localReportId = _newLocalId('lost_report');
      final pendingPayload = _buildPendingReportPayload(
        source: data,
        petId: normalizedPetId,
        reportId: localReportId,
      );
      await _localDb.upsertEntity(
        table: LocalDbTables.lostPets,
        remoteId: localReportId,
        payload: pendingPayload,
        syncStatus: isUpdate ? 'pending_update' : 'pending_create',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypeLostPetReport,
        entityId: localReportId,
        action: isUpdate ? _actionUpdateReport : _actionCreateReport,
        payload: <String, dynamic>{
          'petId': normalizedPetId,
          'data': _asMap(data),
        },
      );
      await _markLocalPetStatus(normalizedPetId, 'lost');
      await _invalidateLostPetsCache();
      await _invalidatePetCaches();
      return LostPetReportModel.fromJson(pendingPayload);
    }
  }

  Future<void> markPetAsFound(String petId) async {
    final normalizedPetId = petId.trim();
    try {
      final response = await _apiClient.post(
        '/api/pets/$normalizedPetId/mark-found/',
      );
      await _persistResolvedReportFromMarkFoundResponse(response.body);
      await _markLocalReportsForPetResolved(normalizedPetId);
      await _markLocalPetStatus(normalizedPetId, 'healthy');
      await _invalidateLostPetsCache();
      await _invalidatePetCaches();
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }
      await _markLocalReportsForPetResolved(normalizedPetId);
      await _markLocalPetStatus(normalizedPetId, 'healthy');
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypeLostPetReport,
        entityId: normalizedPetId,
        action: _actionResolveReport,
        payload: <String, dynamic>{'petId': normalizedPetId},
      );
      await _invalidateLostPetsCache();
      await _invalidatePetCaches();
    }
  }

  Future<void> retryPendingSyncOperations({int limit = 30}) async {
    final reportOperations = await _localDb.getPendingSyncOperations(
      entityType: _entityTypeLostPetReport,
      limit: limit,
    );

    for (final operation in reportOperations) {
      try {
        final payload = operation.payload ?? const <String, dynamic>{};
        final petId = await _resolvePetIdForSync(
          (payload['petId'] as String?)?.trim(),
        );
        if (petId.isEmpty) {
          throw const ApiException(
            type: ApiErrorType.unknown,
            message: 'Missing petId in queued lost report operation.',
          );
        }

        switch (operation.action) {
          case _actionCreateReport:
            final response = await _apiClient.post(
              '/api/pets/$petId/lost-report/',
              body: _asMap(payload['data']),
            );
            await _persistResponseReport(response.body);
            await _deleteLocalPendingReport(operation.entityId);
            break;
          case _actionUpdateReport:
            final response = await _apiClient.put(
              '/api/pets/$petId/lost-report/',
              body: _asMap(payload['data']),
            );
            await _persistResponseReport(response.body);
            await _deleteLocalPendingReport(operation.entityId);
            break;
          case _actionResolveReport:
            final response = await _apiClient.post(
              '/api/pets/$petId/mark-found/',
            );
            await _persistResolvedReportFromMarkFoundResponse(response.body);
            await _markLocalReportsForPetResolved(petId);
            await _markLocalPetStatus(petId, 'healthy');
            await _deleteLocalPendingReport(operation.entityId);
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

  List<LostPetReportModel> _parseReports(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected lost pets response from server.',
      );
    }
    return decoded
        .map(_asMap)
        .map(LostPetReportModel.fromJson)
        .toList(growable: false);
  }

  List<LostPetReportModel>? _tryParseReports(String body) {
    try {
      return _parseReports(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistResponseReport(String body) async {
    if (body.trim().isEmpty) {
      return;
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      await _persistReportMap(decoded);
    } else if (decoded is Map) {
      await _persistReportMap(_asMap(decoded));
    }
  }

  Future<void> _persistReportsFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List<dynamic>) {
        return;
      }
      final remoteIds = <String>[];
      for (final item in decoded) {
        final map = _asMap(item);
        await _persistReportMap(map);
        final remoteId = _readRemoteId(map);
        if (remoteId != null) {
          remoteIds.add(remoteId);
        }
      }
      if (remoteIds.isNotEmpty) {
        await _localDb.deleteEntitiesNotIn(
          table: LocalDbTables.lostPets,
          keepRemoteIds: remoteIds,
        );
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistReportMap(Map<String, dynamic> reportJson) async {
    final remoteId = _readRemoteId(reportJson);
    if (remoteId == null) {
      return;
    }
    await _localDb.upsertEntity(
      table: LocalDbTables.lostPets,
      remoteId: remoteId,
      payload: reportJson,
    );
  }

  Future<List<LostPetReportModel>> _getReportsFromLocalDb() async {
    try {
      final localRows = await _localDb.getAllEntities(LocalDbTables.lostPets);
      return localRows
          .where((row) => (row['status'] as String?) == 'active')
          .map(LostPetReportModel.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <LostPetReportModel>[];
    }
  }

  Future<void> _invalidateLostPetsCache() async {
    try {
      await _cache.clear(_lostPetsCacheKey);
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  Future<void> _invalidatePetCaches() async {
    try {
      await _cache.clear('pets.mine');
      await _cache.clear('users.current');
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  Future<void> _markLocalPetStatus(String petId, String status) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      return;
    }

    try {
      final petJson = await _localDb.getEntityById(
        table: LocalDbTables.pets,
        remoteId: normalizedPetId,
      );
      if (petJson == null) {
        return;
      }

      final nextPetJson = <String, dynamic>{...petJson, 'status': status};
      await _localDb.upsertEntity(
        table: LocalDbTables.pets,
        remoteId: normalizedPetId,
        payload: nextPetJson,
      );
    } catch (_) {
      // Local status sync is best effort.
    }
  }

  Future<void> _persistResolvedReportFromMarkFoundResponse(String body) async {
    if (body.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(body);
      final map = _asMap(decoded);
      final report = map['report'];
      if (report is Map) {
        await _persistReportMap(_asMap(report));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _markLocalReportsForPetResolved(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      return;
    }

    try {
      final localRows = await _localDb.getAllEntities(LocalDbTables.lostPets);
      final now = DateTime.now().toIso8601String();
      for (final row in localRows) {
        final rowPetId = _readPetId(row);
        if (rowPetId != normalizedPetId) {
          continue;
        }

        final remoteId = _readRemoteId(row);
        if (remoteId == null) {
          continue;
        }

        await _localDb.upsertEntity(
          table: LocalDbTables.lostPets,
          remoteId: remoteId,
          payload: <String, dynamic>{
            ...row,
            'status': 'resolved',
            'resolvedAt': row['resolvedAt'] ?? row['resolved_at'] ?? now,
          },
        );
      }
    } catch (_) {
      // Local report resolution is best effort.
    }
  }

  Map<String, dynamic> _buildPendingReportPayload({
    required Map<String, dynamic> source,
    required String petId,
    required String reportId,
  }) {
    final map = _asMap(source);
    final lastSeen = _asMap(map['lastSeen'] ?? map['last_seen']);
    return <String, dynamic>{
      'id': reportId,
      'petId': petId,
      'ownerId': '',
      'city': map['city'] ?? 'Bogotá',
      'status': 'active',
      'petName': map['petName'] ?? '',
      'species': map['species'] ?? '',
      'breed': map['breed'] ?? '',
      'gender': map['gender'] ?? '',
      'color': map['color'] ?? '',
      'weight': map['weight'],
      'photoUrl': map['photoUrl'],
      'knownAllergies': map['knownAllergies'] ?? '',
      'defaultVet': map['defaultVet'] ?? '',
      'defaultClinic': map['defaultClinic'] ?? '',
      'lostNote': map['lostNote'] ?? '',
      'exposeMedicalInfo': map['exposeMedicalInfo'] ?? false,
      'nfcNotificationsEnabled': map['nfcNotificationsEnabled'] ?? true,
      'lastSeen': lastSeen.isNotEmpty
          ? lastSeen
          : {
              'name': map['lastSeenLocation'] ?? map['last_seen_location'],
              'latitude': map['lastSeenLatitude'] ?? map['last_seen_latitude'],
              'longitude':
                  map['lastSeenLongitude'] ?? map['last_seen_longitude'],
              'seenAt': map['lastSeenAt'] ?? map['last_seen_at'],
            },
      'contacts':
          map['contacts'] ?? map['emergencyContacts'] ?? const <dynamic>[],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _asMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  String? _readRemoteId(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id is String && id.trim().isNotEmpty) {
      return id.trim();
    }
    if (id is Map) {
      final oid = id['\$oid'];
      if (oid is String && oid.trim().isNotEmpty) {
        return oid.trim();
      }
    }
    return null;
  }

  String? _readPetId(Map<String, dynamic> json) {
    final petId = json['petId'] ?? json['pet_id'];
    if (petId is String && petId.trim().isNotEmpty) {
      return petId.trim();
    }

    final pet = json['pet'];
    if (pet is Map) {
      final id = pet['id'] ?? pet['_id'];
      if (id is String && id.trim().isNotEmpty) {
        return id.trim();
      }
      if (id is Map) {
        final oid = id['\$oid'];
        if (oid is String && oid.trim().isNotEmpty) {
          return oid.trim();
        }
      }
    }

    return null;
  }

  String _newLocalId(String prefix) {
    return 'local_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _resolvePetIdForSync(String? petId) async {
    final trimmed = petId?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }

    final mapped = await _localDb.getMetaValue(
      '$_petIdMappingMetaPrefix$trimmed',
    );
    final mappedTrimmed = mapped?.trim() ?? '';
    return mappedTrimmed.isNotEmpty ? mappedTrimmed : trimmed;
  }

  Future<void> _deleteLocalPendingReport(String reportId) async {
    final normalized = reportId.trim();
    if (!normalized.startsWith('local_')) {
      return;
    }
    try {
      await _localDb.deleteEntity(
        table: LocalDbTables.lostPets,
        remoteId: normalized,
      );
    } catch (_) {
      // Best effort cleanup after a queued report sync succeeds.
    }
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }
}
