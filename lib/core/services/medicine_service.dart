import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_frontend/core/models/medicine_model.dart';
import 'package:flutter_frontend/core/models/medicine_request.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import 'attachment_upload_service.dart';
import 'local_database_service.dart';
import 'response_cache_service.dart';

class MedicineService {
  MedicineService._();

  static final MedicineService _instance = MedicineService._();
  factory MedicineService() => _instance;

  static const String medicinesPath = '/api/medicines/';
  static const String _entityType = 'medicine';
  static const String _actionCreate = 'create';
  static const String _actionUpdate = 'update';
  static const String _actionDelete = 'delete';
  static const String _medicinesCachePrefix = 'medicines.';
  static const Duration _medicinesCacheTtl = Duration(minutes: 10);
  static const String _petIdMappingMetaPrefix = 'pet_id_map.';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();

  Future<List<MedicineModel>> getMedicines({
    String? petId,
    String? ownerId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKeyForFilter(petId: petId, ownerId: ownerId);
    final cachedEntry = await _cache.get(cacheKey);

    if (!forceRefresh &&
        cachedEntry != null &&
        cachedEntry.isFresh(_medicinesCacheTtl)) {
      final cachedMedicines = _tryParseMedicines(cachedEntry.body);
      if (cachedMedicines != null) {
        unawaited(_persistMedicinesFromBody(cachedEntry.body));
        return _filterMedicines(cachedMedicines, petId: petId, ownerId: ownerId);
      }
    }

    final query = StringBuffer(medicinesPath);
    final queryParams = <String, String>{};
    final trimmedPetId = petId?.trim() ?? '';
    final trimmedOwnerId = ownerId?.trim() ?? '';
    if (trimmedPetId.isNotEmpty) {
      queryParams['pet_id'] = trimmedPetId;
    } else if (trimmedOwnerId.isNotEmpty) {
      queryParams['owner_id'] = trimmedOwnerId;
    }

    if (queryParams.isNotEmpty) {
      query.write('?');
      query.write(
        queryParams.entries
            .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
            .join('&'),
      );
    }

    try {
      final response = await _apiClient.get(query.toString());
      final medicines = _parseMedicines(response.body);
      await _cache.set(cacheKey, response.body);
      await _persistMedicinesFromBody(response.body);
      return _filterMedicines(medicines, petId: petId, ownerId: ownerId);
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackMedicines = _tryParseMedicines(cachedEntry.body);
        if (fallbackMedicines != null) {
          unawaited(_persistMedicinesFromBody(cachedEntry.body));
          return _filterMedicines(
            fallbackMedicines,
            petId: petId,
            ownerId: ownerId,
          );
        }
      }

      final localMedicines = await _getMedicinesFromLocalDb(
        petId: petId,
        ownerId: ownerId,
      );
      if (localMedicines.isNotEmpty) {
        return localMedicines;
      }
      rethrow;
    }
  }

  Future<List<MedicineModel>> getMedicinesForPets(List<String> petIds) async {
    final results = <MedicineModel>[];
    for (final petId in petIds) {
      try {
        final medicines = await getMedicines(petId: petId);
        results.addAll(medicines);
      } catch (_) {
        // ignore failures for individual pets
      }
    }
    return results;
  }

  Future<MedicineModel> createMedicine(MedicineRequest request) async {
    try {
      final apiPayload = await _prepareMedicinePayloadForApi(request.toJson());
      final response = await _apiClient.post(medicinesPath, body: apiPayload);
      final createdMedicine = _decodeMedicineMap(
        response.body,
        fallbackMessage: 'Unexpected medicine create response.',
      );
      await _persistMedicineMap(_medicineToMap(createdMedicine));
      await _invalidateMedicinesCache();
      return createdMedicine;
    } catch (error) {
      if (!_shouldQueueOffline(error) &&
          !_shouldQueuePendingPhotoResolution(error, request.toJson())) {
        rethrow;
      }

      final localId = _newLocalId('medicine');
      final pendingPayload = _buildPendingMedicinePayload(
        source: request.toJson(),
        medicineId: localId,
      );

      await _localDb.upsertEntity(
        table: LocalDbTables.medicines,
        remoteId: localId,
        payload: pendingPayload,
        syncStatus: 'pending_create',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: localId,
        action: _actionCreate,
        payload: request.toJson(),
      );
      await _invalidateMedicinesCache();
      return MedicineModel.fromJson(pendingPayload);
    }
  }

  Future<MedicineModel> getMedicineById(String medicineId) async {
    final trimmedMedicineId = medicineId.trim();
    try {
      final response = await _apiClient.get('$medicinesPath$trimmedMedicineId/');
      final medicine = _decodeMedicineMap(
        response.body,
        fallbackMessage: 'Unexpected medicine detail response.',
      );
      await _persistMedicineMap(_medicineToMap(medicine));
      return medicine;
    } catch (_) {
      final localMedicineJson = await _localDb.getEntityById(
        table: LocalDbTables.medicines,
        remoteId: trimmedMedicineId,
      );
      if (localMedicineJson != null) {
        return MedicineModel.fromJson(localMedicineJson);
      }
      rethrow;
    }
  }

  Future<MedicineModel> updateMedicine({
    required String medicineId,
    required MedicineRequest request,
  }) async {
    final trimmedMedicineId = medicineId.trim();
    try {
      final apiPayload = await _prepareMedicinePayloadForApi(request.toJson());
      final response = await _apiClient.put(
        '$medicinesPath$trimmedMedicineId/',
        body: apiPayload,
      );
      final updatedMedicine = _decodeMedicineMap(
        response.body,
        fallbackMessage: 'Unexpected medicine update response.',
      );
      await _persistMedicineMap(_medicineToMap(updatedMedicine));
      await _invalidateMedicinesCache();
      return updatedMedicine;
    } catch (error) {
      if (!_shouldQueueOffline(error) &&
          !_shouldQueuePendingPhotoResolution(error, request.toJson())) {
        rethrow;
      }

      final current = await _localDb.getEntityById(
            table: LocalDbTables.medicines,
            remoteId: trimmedMedicineId,
          ) ??
          _buildPendingMedicinePayload(
            source: request.toJson(),
            medicineId: trimmedMedicineId,
          );

      final merged = <String, dynamic>{
        ...current,
        ...request.toJson(),
      };
      merged['id'] = trimmedMedicineId;

      await _localDb.upsertEntity(
        table: LocalDbTables.medicines,
        remoteId: trimmedMedicineId,
        payload: merged,
        syncStatus: 'pending_update',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedMedicineId,
        action: _actionUpdate,
        payload: request.toJson(),
      );
      await _invalidateMedicinesCache();
      return MedicineModel.fromJson(merged);
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    final trimmedMedicineId = medicineId.trim();
    try {
      await _apiClient.delete('$medicinesPath$trimmedMedicineId/');
      await _localDb.deleteEntity(
        table: LocalDbTables.medicines,
        remoteId: trimmedMedicineId,
      );
      await _invalidateMedicinesCache();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        await _localDb.deleteEntity(
          table: LocalDbTables.medicines,
          remoteId: trimmedMedicineId,
        );
        await _invalidateMedicinesCache();
        return;
      }

      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      await _localDb.deleteEntity(
        table: LocalDbTables.medicines,
        remoteId: trimmedMedicineId,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedMedicineId,
        action: _actionDelete,
      );
      await _invalidateMedicinesCache();
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
            final createPayload = _asStringDynamicMap(
              operation.payload ?? const <String, dynamic>{},
            );
            final resolvedCreatePayload = await _prepareMedicinePayloadForApi(
              createPayload,
            );
            final response = await _apiClient.post(
              medicinesPath,
              body: resolvedCreatePayload,
            );
            final created = _decodeMedicineMap(
              response.body,
              fallbackMessage: 'Unexpected medicine create response.',
            );
            await _localDb.deleteEntity(
              table: LocalDbTables.medicines,
              remoteId: operation.entityId,
            );
            await _persistMedicineMap(_medicineToMap(created));
            break;
          case _actionUpdate:
            final updatePayload = _asStringDynamicMap(
              operation.payload ?? const <String, dynamic>{},
            );
            final resolvedUpdatePayload = await _prepareMedicinePayloadForApi(
              updatePayload,
            );
            final response = await _apiClient.put(
              '$medicinesPath${operation.entityId}/',
              body: resolvedUpdatePayload,
            );
            final updated = _decodeMedicineMap(
              response.body,
              fallbackMessage: 'Unexpected medicine update response.',
            );
            await _persistMedicineMap(_medicineToMap(updated));
            break;
          case _actionDelete:
            try {
              await _apiClient.delete('$medicinesPath${operation.entityId}/');
            } on ApiException catch (error) {
              if (error.statusCode != 404) {
                rethrow;
              }
            }
            await _localDb.deleteEntity(
              table: LocalDbTables.medicines,
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

  Future<List<MedicineModel>> _getMedicinesFromLocalDb({
    String? petId,
    String? ownerId,
  }) async {
    final medicines = await _localDb.getAllEntities(LocalDbTables.medicines);
    final filtered = _filterMedicines(
      medicines.map(MedicineModel.fromJson).toList(growable: false),
      petId: petId,
      ownerId: ownerId,
    );
    return filtered;
  }

  List<MedicineModel> _filterMedicines(
    List<MedicineModel> medicines, {
    String? petId,
    String? ownerId,
  }) {
    final trimmedPetId = petId?.trim() ?? '';
    final trimmedOwnerId = ownerId?.trim() ?? '';
    if (trimmedPetId.isEmpty && trimmedOwnerId.isEmpty) {
      return medicines;
    }

    return medicines.where((medicine) {
      if (trimmedPetId.isNotEmpty && medicine.petId.trim() != trimmedPetId) {
        return false;
      }
      if (trimmedOwnerId.isNotEmpty && medicine.ownerId.trim() != trimmedOwnerId) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>> _prepareMedicinePayloadForApi(
    Map<String, dynamic> payload,
  ) async {
    final prepared = <String, dynamic>{...payload};
    final resolved = await _resolveMedicinePayloadPetIdForSync(prepared);
    final photoUrl = (resolved['photoUrl'] as String?)?.trim() ?? '';
    if (photoUrl.isNotEmpty && !_isRemotePhotoUrl(photoUrl)) {
      final file = File(photoUrl);
      if (!await file.exists()) {
        throw Exception('Medicine photo file not found.');
      }

      final uploaded = await _attachmentUploadService.uploadMedicinePhoto(
        bytes: await file.readAsBytes(),
        fileName: p.basename(photoUrl),
      );

      if (uploaded.isPendingUpload) {
        throw Exception('Medicine photo upload still pending.');
      }

      resolved['photoUrl'] = uploaded.downloadUrl;
    }

    return resolved;
  }

  Future<Map<String, dynamic>> _resolveMedicinePayloadPetIdForSync(
    Map<String, dynamic> payload,
  ) async {
    final resolved = <String, dynamic>{...payload};
    final rawPetId = (resolved['petId'] ?? resolved['pet_id'])?.toString();
    final mappedPetId = await _resolvePetIdForSync(rawPetId);
    if (mappedPetId == null || mappedPetId.trim().isEmpty) {
      return resolved;
    }

    if (resolved.containsKey('petId')) {
      resolved['petId'] = mappedPetId;
    }
    if (resolved.containsKey('pet_id')) {
      resolved['pet_id'] = mappedPetId;
    }
    if (!resolved.containsKey('petId') && !resolved.containsKey('pet_id')) {
      resolved['petId'] = mappedPetId;
    }

    return resolved;
  }

  Future<String?> _resolvePetIdForSync(String? petId) async {
    final trimmed = petId?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final mapped = await _localDb.getMetaValue(
      '$_petIdMappingMetaPrefix$trimmed',
    );
    final mappedTrimmed = mapped?.trim() ?? '';
    if (mappedTrimmed.isNotEmpty) {
      return mappedTrimmed;
    }

    return trimmed;
  }

  Future<void> _persistMedicinesFromBody(String responseBody) async {
    try {
      final decoded = _decodeJson(responseBody);
      final items = _extractMedicineItems(decoded);
      for (final item in items) {
        await _persistMedicineMap(_asStringDynamicMap(item));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistMedicineMap(Map<String, dynamic> medicineJson) async {
    final remoteId = _readRemoteId(medicineJson);
    if (remoteId == null) {
      return;
    }

    final payload = <String, dynamic>{...medicineJson};
    payload['id'] = remoteId;

    await _localDb.upsertEntity(
      table: LocalDbTables.medicines,
      remoteId: remoteId,
      payload: payload,
    );
  }

  Future<void> _invalidateMedicinesCache() async {
    try {
      await _cache.clearByPrefix(_medicinesCachePrefix);
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  MedicineModel _decodeMedicineMap(
    String responseBody, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeJson(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(type: ApiErrorType.unknown, message: fallbackMessage);
    }

    return MedicineModel.fromJson(decoded);
  }

  List<MedicineModel> _parseMedicines(String responseBody) {
    final decoded = _decodeJson(responseBody);
    final medicineItems = _extractMedicineItems(decoded);

    return medicineItems
        .map(_asStringDynamicMap)
        .map(MedicineModel.fromJson)
        .toList(growable: false);
  }

  List<MedicineModel>? _tryParseMedicines(String responseBody) {
    try {
      return _parseMedicines(responseBody);
    } catch (_) {
      return null;
    }
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }

  List<dynamic> _extractMedicineItems(dynamic decoded) {
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
      message: 'Unexpected medicines response from server.',
    );
  }

  Map<String, dynamic> _medicineToMap(MedicineModel medicine) {
    return <String, dynamic>{
      'id': medicine.id,
      'schema': medicine.schema,
      'petId': medicine.petId,
      'ownerId': medicine.ownerId,
      'medicineName': medicine.medicineName,
      'administrationRoute': medicine.administrationRoute,
      'dosageValue': medicine.dosageValue,
      'dosageUnit': medicine.dosageUnit,
      'frequency': medicine.frequency,
      'startDate': medicine.startDate?.toIso8601String(),
      'endDate': medicine.endDate?.toIso8601String(),
      'photoUrl': medicine.photoUrl,
      'reminderEnabled': medicine.reminderEnabled,
      'lastAdministered': medicine.lastAdministered?.toIso8601String(),
    };
  }

  Map<String, dynamic> _buildPendingMedicinePayload({
    required Map<String, dynamic> source,
    required String medicineId,
  }) {
    final map = _asStringDynamicMap(source);
    return <String, dynamic>{
      'id': medicineId,
      'schema': map['schema'] ?? 1,
      'petId': map['petId'] ?? map['pet_id'] ?? '',
      'ownerId': map['ownerId'] ?? map['owner_id'] ?? '',
      'medicineName': map['medicineName'] ?? map['medicine_name'] ?? '',
      'administrationRoute':
          map['administrationRoute'] ?? map['administration_route'] ?? '',
      'dosageValue': map['dosageValue'] ?? map['dosage_value'] ?? 0,
      'dosageUnit': map['dosageUnit'] ?? map['dosage_unit'] ?? 'mg',
      'frequency': map['frequency'] ?? 0,
      'startDate': map['startDate'] ?? map['start_date'],
      'endDate': map['endDate'] ?? map['end_date'],
      'photoUrl': map['photoUrl'] ?? map['photo_url'],
      'reminderEnabled': map['reminderEnabled'] ?? map['reminder_enabled'] ?? false,
      'lastAdministered': map['lastAdministered'] ?? map['last_administered'],
    };
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

  String _cacheKeyForFilter({String? petId, String? ownerId}) {
    final trimmedPetId = petId?.trim() ?? '';
    final trimmedOwnerId = ownerId?.trim() ?? '';
    if (trimmedPetId.isNotEmpty) {
      return '${_medicinesCachePrefix}pet.$trimmedPetId';
    }
    if (trimmedOwnerId.isNotEmpty) {
      return '${_medicinesCachePrefix}owner.$trimmedOwnerId';
    }
    return '${_medicinesCachePrefix}all';
  }

  String? _readRemoteId(Map<String, dynamic> medicineJson) {
    final id = medicineJson['id'] ?? medicineJson['_id'] ?? medicineJson['medicineId'];
    if (id is String && id.trim().isNotEmpty) {
      return id.trim();
    }

    if (id is Map) {
      final oid = id[r'$oid'];
      if (oid is String && oid.trim().isNotEmpty) {
        return oid.trim();
      }
    }

    return null;
  }

  bool _isRemotePhotoUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _newLocalId(String prefix) {
    return 'local_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }

  bool _shouldQueuePendingPhotoResolution(
    Object error,
    Map<String, dynamic> data,
  ) {
    final message = error.toString();
    return message.contains('Medicine photo upload still pending') &&
        (data['photoUrl'] as String?)?.trim().isNotEmpty == true;
  }
}