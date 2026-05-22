import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_frontend/core/models/exercise_model.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import 'local_database_service.dart';
import 'response_cache_service.dart';

class ExerciseService {
  ExerciseService._();

  static final ExerciseService _instance = ExerciseService._();

  factory ExerciseService() => _instance;

  static const String _petsPath = '/api/pets/';
  static const String _exercisesCachePrefix = 'exercises.byPet.';
  static const Duration _exercisesCacheTtl = Duration(minutes: 5);
  static const String _entityType = 'exercise';
  static const String _actionCreate = 'create';
  static const String _actionUpdate = 'update';
  static const String _actionDelete = 'delete';
  static const String _petIdMappingMetaPrefix = 'pet_id_map.';
  static const int _weeklyGoalMinutes = 150;

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<List<ExerciseModel>> getExercisesByPet(
    String petId, {
    bool forceRefresh = false,
  }) async {
    final trimmedPetId = petId.trim();
    final apiPetId = await _resolvePetIdForSync(trimmedPetId);
    final cacheKey = _exercisesByPetCacheKey(trimmedPetId);
    final cachedEntry = await _cache.get(cacheKey);
    if (!forceRefresh &&
        cachedEntry != null &&
        cachedEntry.isFresh(_exercisesCacheTtl)) {
      final cachedExercises = _tryParseExercises(cachedEntry.body);
      if (cachedExercises != null) {
        unawaited(_persistExercisesFromBody(cachedEntry.body));
        final merged = await _mergeLocalExercises(cachedExercises);
        return _filterExercisesByPet(
          merged,
          trimmedPetId,
          mappedPetId: apiPetId,
        );
      }
    }

    try {
      final response = await _apiClient.get(_exercisesPathForPet(apiPetId));
      final exercises = _parseExercises(response.body);
      await _cache.set(cacheKey, response.body);
      await _persistExercisesFromBody(response.body);
      final merged = await _mergeLocalExercises(exercises);
      return _filterExercisesByPet(
        merged,
        trimmedPetId,
        mappedPetId: apiPetId,
      );
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackExercises = _tryParseExercises(cachedEntry.body);
        if (fallbackExercises != null) {
          unawaited(_persistExercisesFromBody(cachedEntry.body));
          final merged = await _mergeLocalExercises(fallbackExercises);
          return _filterExercisesByPet(
            merged,
            trimmedPetId,
            mappedPetId: apiPetId,
          );
        }
      }

      final localExercises = await _getExercisesFromLocalDb();
      if (localExercises.isNotEmpty) {
        return _filterExercisesByPet(
          localExercises,
          trimmedPetId,
          mappedPetId: apiPetId,
        );
      }
      rethrow;
    }
  }

  Future<ExerciseModel> createExercise({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    final trimmedPetId = petId.trim();
    final apiPetId = await _resolvePetIdForSync(trimmedPetId);
    final hasUnresolvedLocalPet =
        _isLocalId(trimmedPetId) && apiPetId == trimmedPetId;
    try {
      final apiPayload = _prepareExercisePayloadForApi(
        _withPetId(data, apiPetId),
      );
      final response = await _apiClient.post(
        _exercisesPathForPet(apiPetId),
        body: apiPayload,
      );
      final createdExercise = _decodeExerciseMap(
        response.body,
        fallbackMessage: 'Unexpected create exercise response.',
      );
      await _persistExerciseMap(createdExercise.toJson());
      await _invalidateExercisesCache();
      return createdExercise;
    } catch (error) {
      if (!_shouldQueueOffline(error) && !hasUnresolvedLocalPet) {
        rethrow;
      }

      final localId = _newLocalId('exercise');
      final pendingPayload = _buildPendingExercisePayload(
        source: <String, dynamic>{...data, 'petId': trimmedPetId},
        exerciseId: localId,
      );

      await _localDb.upsertEntity(
        table: LocalDbTables.exercises,
        remoteId: localId,
        payload: pendingPayload,
        syncStatus: 'pending_create',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: localId,
        action: _actionCreate,
        payload: <String, dynamic>{
          'petId': trimmedPetId,
          'data': _asStringDynamicMap(data),
        },
      );
      await _invalidateExercisesCache();
      return ExerciseModel.fromJson(pendingPayload);
    }
  }

  Future<ExerciseModel> updateExercise({
    required String petId,
    required String exerciseId,
    required Map<String, dynamic> data,
  }) async {
    final trimmedPetId = petId.trim();
    final trimmedExerciseId = exerciseId.trim();
    final apiPetId = await _resolvePetIdForSync(trimmedPetId);
    final hasUnresolvedLocalPet =
        _isLocalId(trimmedPetId) && apiPetId == trimmedPetId;
    try {
      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.exercises,
            remoteId: trimmedExerciseId,
          ) ??
          const <String, dynamic>{};
      final response = await _apiClient.put(
        _exerciseDetailPath(
          petId: apiPetId,
          exerciseId: trimmedExerciseId,
        ),
        body: _prepareExercisePayloadForApi(_withPetId(data, apiPetId)),
      );
      if (response.body.trim().isNotEmpty) {
        final updatedExercise = _decodeExerciseMap(
          response.body,
          fallbackMessage: 'Unexpected update exercise response.',
        );
        await _persistExerciseMap(
          updatedExercise.toJson(),
          preservePendingLocal: false,
        );
        await _invalidateExercisesCache();
        return updatedExercise;
      }

      final merged = <String, dynamic>{...current, ..._asStringDynamicMap(data)};
      merged['id'] = trimmedExerciseId;
      merged['petId'] = trimmedPetId;
      merged['updatedAt'] = DateTime.now().toIso8601String();
      await _persistExerciseMap(merged, preservePendingLocal: false);
      await _invalidateExercisesCache();
      return ExerciseModel.fromJson(merged);
    } catch (error) {
      if (!_shouldQueueOffline(error) && !hasUnresolvedLocalPet) {
        rethrow;
      }

      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.exercises,
            remoteId: trimmedExerciseId,
          ) ??
          _buildPendingExercisePayload(
            source: <String, dynamic>{...data, 'petId': trimmedPetId},
            exerciseId: trimmedExerciseId,
          );

      final merged = <String, dynamic>{...current, ..._asStringDynamicMap(data)};
      merged['id'] = trimmedExerciseId;
      merged['petId'] = trimmedPetId;
      merged['updatedAt'] = DateTime.now().toIso8601String();

      await _localDb.upsertEntity(
        table: LocalDbTables.exercises,
        remoteId: trimmedExerciseId,
        payload: merged,
        syncStatus: 'pending_update',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedExerciseId,
        action: _actionUpdate,
        payload: <String, dynamic>{
          'petId': trimmedPetId,
          'data': _asStringDynamicMap(data),
        },
      );
      await _invalidateExercisesCache();
      return ExerciseModel.fromJson(merged);
    }
  }

  Future<void> deleteExercise({
    required String petId,
    required String exerciseId,
  }) async {
    final trimmedPetId = petId.trim();
    final trimmedExerciseId = exerciseId.trim();
    final apiPetId = await _resolvePetIdForSync(trimmedPetId);
    final hasUnresolvedLocalPet =
        _isLocalId(trimmedPetId) && apiPetId == trimmedPetId;
    try {
      await _apiClient.delete(
        _exerciseDetailPath(
          petId: apiPetId,
          exerciseId: trimmedExerciseId,
        ),
      );
      await _localDb.deleteEntity(
        table: LocalDbTables.exercises,
        remoteId: trimmedExerciseId,
      );
      await _invalidateExercisesCache();
    } catch (error) {
      if (error is ApiException && error.statusCode == 404) {
        await _localDb.deleteEntity(
          table: LocalDbTables.exercises,
          remoteId: trimmedExerciseId,
        );
        await _invalidateExercisesCache();
        return;
      }

      if (!_shouldQueueOffline(error) && !hasUnresolvedLocalPet) {
        rethrow;
      }

      await _localDb.deleteEntity(
        table: LocalDbTables.exercises,
        remoteId: trimmedExerciseId,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedExerciseId,
        action: _actionDelete,
        payload: <String, dynamic>{'petId': trimmedPetId},
      );
      await _invalidateExercisesCache();
    }
  }

  Future<void> retryPendingSyncOperations({int limit = 30}) async {
    final operations = await _localDb.getPendingSyncOperations(
      entityType: _entityType,
      limit: limit,
    );

    for (final operation in operations) {
      try {
        switch (operation.action) {
          case _actionCreate:
            final payload = _asStringDynamicMap(
              operation.payload ?? const <String, dynamic>{},
            );
            final petId = await _resolvePetIdForSync(
              _readStringValue(payload['petId']),
            );
            final createPayload = _withPetId(
              _asStringDynamicMap(payload['data']),
              petId,
            );
            final response = await _apiClient.post(
              _exercisesPathForPet(petId),
              body: _prepareExercisePayloadForApi(createPayload),
            );
            final createdExercise = _decodeExerciseMap(
              response.body,
              fallbackMessage: 'Unexpected create exercise response.',
            );
            await _localDb.deleteEntity(
              table: LocalDbTables.exercises,
              remoteId: operation.entityId,
            );
            await _persistExerciseMap(
              createdExercise.toJson(),
              preservePendingLocal: false,
            );
            break;
          case _actionUpdate:
            final payload = _asStringDynamicMap(
              operation.payload ?? const <String, dynamic>{},
            );
            final petId = await _resolvePetIdForSync(
              _readStringValue(payload['petId']),
            );
            final updatePayload = _withPetId(
              _asStringDynamicMap(payload['data']),
              petId,
            );
            final current =
                await _localDb.getEntityById(
                  table: LocalDbTables.exercises,
                  remoteId: operation.entityId,
                ) ??
                const <String, dynamic>{};
            final response = await _apiClient.put(
              _exerciseDetailPath(
                petId: petId,
                exerciseId: operation.entityId,
              ),
              body: _prepareExercisePayloadForApi(updatePayload),
            );
            if (response.body.trim().isNotEmpty) {
              final updatedExercise = _decodeExerciseMap(
                response.body,
                fallbackMessage: 'Unexpected update exercise response.',
              );
              await _persistExerciseMap(
                updatedExercise.toJson(),
                preservePendingLocal: false,
              );
            } else {
              final merged = <String, dynamic>{...current, ...updatePayload};
              merged['id'] = operation.entityId;
              merged['petId'] = petId;
              merged['updatedAt'] = DateTime.now().toIso8601String();
              await _persistExerciseMap(
                merged,
                preservePendingLocal: false,
              );
            }
            break;
          case _actionDelete:
            final payload = _asStringDynamicMap(
              operation.payload ?? const <String, dynamic>{},
            );
            final petId = await _resolvePetIdForSync(
              _readStringValue(payload['petId']),
            );
            try {
              await _apiClient.delete(
                _exerciseDetailPath(
                  petId: petId,
                  exerciseId: operation.entityId,
                ),
              );
            } on ApiException catch (error) {
              if (error.statusCode != 404) {
                rethrow;
              }
            }
            await _localDb.deleteEntity(
              table: LocalDbTables.exercises,
              remoteId: operation.entityId,
            );
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

  Future<ExerciseWeeklySummary> summarizeExercises(
    List<ExerciseModel> exercises, {
    String? petId,
    DateTime? referenceDate,
  }) {
    return Isolate.run(
      () => _summarizeExercisesOnWorker(
        exercises.map((exercise) => exercise.toJson()).toList(growable: false),
        petId: petId,
        referenceDateIso:
            (referenceDate ?? DateTime.now()).toIso8601String(),
        goalMinutes: _weeklyGoalMinutes,
      ),
    );
  }

  List<ExerciseModel> _parseExercises(String responseBody) {
    final decoded = _decodeJson(responseBody);
    final items = _extractExerciseItems(decoded);
    return items
        .map(_asStringDynamicMap)
        .map(ExerciseModel.fromJson)
        .toList(growable: false)
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
  }

  List<ExerciseModel>? _tryParseExercises(String responseBody) {
    try {
      return _parseExercises(responseBody);
    } catch (_) {
      return null;
    }
  }

  List<ExerciseModel> _filterExercisesByPet(
    List<ExerciseModel> exercises,
    String petId, {
    String? mappedPetId,
  }) {
    final allowedPetIds = <String>{
      petId.trim(),
      if (mappedPetId != null && mappedPetId.trim().isNotEmpty)
        mappedPetId.trim(),
    };
    return exercises
        .where((exercise) => allowedPetIds.contains(exercise.petId.trim()))
        .toList(growable: false);
  }

  Future<void> _invalidateExercisesCache() async {
    try {
      await _cache.clearByPrefix(_exercisesCachePrefix);
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  ExerciseModel _decodeExerciseMap(
    String responseBody, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeJson(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(type: ApiErrorType.unknown, message: fallbackMessage);
    }
    return ExerciseModel.fromJson(decoded);
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }

  List<dynamic> _extractExerciseItems(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List<dynamic>) {
        return results;
      }
    }
    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Unexpected exercises response from server.',
    );
  }

  Map<String, dynamic> _asStringDynamicMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }
    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  Future<void> _persistExercisesFromBody(String responseBody) async {
    try {
      final decoded = _decodeJson(responseBody);
      final items = _extractExerciseItems(decoded);
      for (final item in items) {
        await _persistExerciseMap(_asStringDynamicMap(item));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistExerciseMap(
    Map<String, dynamic> exerciseJson, {
    bool preservePendingLocal = true,
  }) async {
    final remoteId = _readRemoteId(exerciseJson);
    if (remoteId == null) {
      return;
    }

    if (preservePendingLocal) {
      final syncStatus = await _localDb.getEntitySyncStatus(
        table: LocalDbTables.exercises,
        remoteId: remoteId,
      );
      if (_isPendingSyncStatus(syncStatus)) {
        return;
      }
    }

    await _localDb.upsertEntity(
      table: LocalDbTables.exercises,
      remoteId: remoteId,
      payload: exerciseJson,
    );
  }

  Future<List<ExerciseModel>> _getExercisesFromLocalDb() async {
    try {
      final localRows = await _localDb.getAllEntities(LocalDbTables.exercises);
      return localRows.map(ExerciseModel.fromJson).toList(growable: false)
        ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    } catch (_) {
      return const <ExerciseModel>[];
    }
  }

  Future<List<ExerciseModel>> _mergeLocalExercises(
    List<ExerciseModel> exercises,
  ) async {
    final localExercises = await _getExercisesFromLocalDb();
    if (localExercises.isEmpty) {
      return exercises;
    }

    final merged = <String, ExerciseModel>{
      for (final exercise in exercises) exercise.id: exercise,
      for (final exercise in localExercises) exercise.id: exercise,
    };

    return merged.values.toList(growable: false)
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
  }

  String? _readRemoteId(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['_id'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is Map) {
      final oid = raw['\$oid'];
      if (oid is String && oid.trim().isNotEmpty) {
        return oid.trim();
      }
    }

    return null;
  }

  bool _isPendingSyncStatus(String? syncStatus) {
    return syncStatus != null && syncStatus.startsWith('pending_');
  }

  bool _shouldQueueOffline(Object error) {
    if (error is ApiException) {
      return error.type == ApiErrorType.network;
    }
    if (error is SocketException || error is TimeoutException) {
      return true;
    }

    final message = error.toString().toLowerCase();
    return message.contains('network-request-failed') ||
        message.contains('network connection failed') ||
        message.contains('failed host lookup') ||
        message.contains('connection closed before full header was received') ||
        message.contains('connection failed') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable') ||
        message.contains('software caused connection abort') ||
        message.contains('timed out') ||
        message.contains('timeout');
  }

  bool _isLocalId(String value) {
    return value.trim().startsWith('local_');
  }

  Future<String> _resolvePetIdForSync(String petId) async {
    final trimmed = petId.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final mapped = await _localDb.getMetaValue(
      '$_petIdMappingMetaPrefix$trimmed',
    );
    final mappedTrimmed = mapped?.trim() ?? '';
    return mappedTrimmed.isNotEmpty ? mappedTrimmed : trimmed;
  }

  String _newLocalId(String prefix) {
    return 'local_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _exercisesPathForPet(String petId) {
    return '$_petsPath$petId/exercises/';
  }

  String _exerciseDetailPath({
    required String petId,
    required String exerciseId,
  }) {
    return '$_petsPath$petId/exercises/$exerciseId/';
  }

  String _exercisesByPetCacheKey(String petId) {
    return '$_exercisesCachePrefix$petId';
  }

  Map<String, dynamic> _buildPendingExercisePayload({
    required Map<String, dynamic> source,
    required String exerciseId,
  }) {
    final map = _asStringDynamicMap(source);
    final nowIso = DateTime.now().toIso8601String();
    return <String, dynamic>{
      'id': exerciseId,
      'petId': map['petId'] ?? map['pet_id'] ?? '',
      'ownerId': map['ownerId'] ?? map['owner_id'] ?? '',
      'type': map['type'] ?? 'walk',
      'startedAt':
          map['startedAt'] ?? map['started_at'] ?? map['date'] ?? nowIso,
      'durationMinutes':
          map['durationMinutes'] ??
          map['duration_minutes'] ??
          map['duration'] ??
          0,
      'intensity': map['intensity'] ?? 'medium',
      'distanceKm': map['distanceKm'] ?? map['distance_km'] ?? map['distance'],
      'notes': map['notes'] ?? '',
      'createdAt': map['createdAt'] ?? map['created_at'] ?? nowIso,
      'updatedAt': map['updatedAt'] ?? map['updated_at'] ?? nowIso,
    };
  }

  Map<String, dynamic> _prepareExercisePayloadForApi(
    Map<String, dynamic> source,
  ) {
    final map = _asStringDynamicMap(source);
    final distanceValue = _readDoubleValue(
      map['distanceKm'] ?? map['distance_km'] ?? map['distance'],
    );

    return <String, dynamic>{
      if (_readStringValue(map['petId'] ?? map['pet_id']).isNotEmpty)
        'pet_id': _readStringValue(map['petId'] ?? map['pet_id']),
      if (_readStringValue(map['ownerId'] ?? map['owner_id']).isNotEmpty)
        'owner_id': _readStringValue(map['ownerId'] ?? map['owner_id']),
      'type': _readStringValue(map['type'], fallback: 'walk'),
      'started_at': _readStringValue(
        map['startedAt'] ?? map['started_at'] ?? map['date'],
        fallback: DateTime.now().toIso8601String(),
      ),
      'duration_minutes': _readIntValue(
        map['durationMinutes'] ?? map['duration_minutes'] ?? map['duration'],
        fallback: 0,
      ),
      'intensity': _readStringValue(map['intensity'], fallback: 'medium'),
      if (distanceValue != null) 'distance_km': distanceValue,
      'notes': _readStringValue(map['notes']),
    };
  }

  Map<String, dynamic> _withPetId(Map<String, dynamic> source, String petId) {
    final map = <String, dynamic>{..._asStringDynamicMap(source)};
    if (petId.trim().isEmpty) {
      return map;
    }

    map['petId'] = petId.trim();
    if (map.containsKey('pet_id')) {
      map['pet_id'] = petId.trim();
    }
    return map;
  }
}

String _readStringValue(dynamic value, {String fallback = ''}) {
  if (value is String) {
    return value.trim();
  }
  if (value == null) {
    return fallback;
  }
  return value.toString().trim();
}

int _readIntValue(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

double? _readDoubleValue(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

ExerciseWeeklySummary _summarizeExercisesOnWorker(
  List<Map<String, dynamic>> items, {
  required String? petId,
  required String referenceDateIso,
  required int goalMinutes,
}) {
  final referenceDate = DateTime.tryParse(referenceDateIso) ?? DateTime.now();
  final weekStart = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  ).subtract(Duration(days: referenceDate.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));
  final trimmedPetId = petId?.trim() ?? '';

  var totalMinutes = 0;
  var totalDistance = 0.0;
  var sessionCount = 0;

  for (final item in items) {
    final exercise = ExerciseModel.fromJson(item);
    if (trimmedPetId.isNotEmpty && exercise.petId != trimmedPetId) {
      continue;
    }
    if (exercise.startedAt.isBefore(weekStart) ||
        !exercise.startedAt.isBefore(weekEnd)) {
      continue;
    }

    totalMinutes += exercise.durationMinutes;
    totalDistance += exercise.distanceKm ?? 0;
    sessionCount += 1;
  }

  return ExerciseWeeklySummary(
    totalMinutes: totalMinutes,
    sessionCount: sessionCount,
    totalDistanceKm: totalDistance,
  );
}
