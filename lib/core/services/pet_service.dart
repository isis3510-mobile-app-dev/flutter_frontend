import 'dart:async';
import 'dart:convert';

import '../models/pet_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'attachment_upload_service.dart';
import 'local_database_service.dart';
import 'response_cache_service.dart';
import 'telemetry_service.dart';

class PetService {
  PetService._();

  static final PetService _instance = PetService._();

  factory PetService() => _instance;

  static const String petsPath = '/api/pets/';
  static const String myPetsPath = '/api/pets/mine';
  static const String _petsCacheKey = 'pets.mine';
  static const Duration _petsCacheTtl = Duration(minutes: 5);

  static const String _entityTypePet = 'pet';
  static const String _entityTypePetVaccination = 'pet_vaccination';

  static const String _actionCreate = 'create';
  static const String _actionUpdate = 'update';
  static const String _actionDelete = 'delete';

  static const String _actionAddVaccination = 'add_vaccination';
  static const String _actionUpdateVaccination = 'update_vaccination';
  static const String _actionDeleteVaccination = 'delete_vaccination';
  static const String _petIdMappingMetaPrefix = 'pet_id_map.';
  static const String _photoUrlKey = 'photoUrl';
  static const String _photoPendingUploadKey = 'photoPendingUpload';
  static const String _photoStoragePathKey = 'photoStoragePath';
  static const String _photoLocalFilePathKey = 'photoLocalFilePath';
  static const String _photoFileNameKey = 'photoFileName';
  static const String _photoContentTypeKey = 'photoContentType';
  static const String _photoSizeBytesKey = 'photoSizeBytes';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final AttachmentUploadService _attachmentUploadService =
      AttachmentUploadService();
  final TelemetryService _telemetryService = TelemetryService();

  Future<List<PetModel>> getPets({bool forceRefresh = false}) async {
    final cachedEntry = await _cache.get(_petsCacheKey);
    if (!forceRefresh &&
        cachedEntry != null &&
        cachedEntry.isFresh(_petsCacheTtl)) {
      final cacheLoadStartTime = DateTime.now();
      final cachedPets = _tryParsePets(cachedEntry.body);
      if (cachedPets != null) {
        unawaited(_persistPetsFromBody(cachedEntry.body));
        final mergedPets = await _mergeLocalPets(cachedPets);
        final cacheLoadEndTime = DateTime.now();
        unawaited(
          _telemetryService.logCachedPetProfileLoadExecution(
            startTime: cacheLoadStartTime,
            endTime: cacheLoadEndTime,
          ),
        );
        return mergedPets;
      }
    }

    try {
      final response = await _apiClient.get(myPetsPath);
      final pets = _parsePets(response.body);
      await _cache.set(_petsCacheKey, response.body);
      await _persistPetsFromBody(response.body);
      return await _mergeLocalPets(pets);
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackPets = _tryParsePets(cachedEntry.body);
        if (fallbackPets != null) {
          unawaited(_persistPetsFromBody(cachedEntry.body));
          return await _mergeLocalPets(fallbackPets);
        }
      }

      final localPets = await _getPetsFromLocalDb();
      if (localPets.isNotEmpty) {
        return localPets;
      }
      rethrow;
    }
  }

  Future<PetModel> getPetById(String petId) async {
    final trimmedPetId = petId.trim();

    final localPetJson = await _localDb.getEntityById(
      table: LocalDbTables.pets,
      remoteId: trimmedPetId,
    );
    if (localPetJson != null) {
      return PetModel.fromJson(localPetJson);
    }

    final resolvedPetId = await _resolvePetIdForSync(trimmedPetId);
    if (resolvedPetId != null && resolvedPetId != trimmedPetId) {
      final resolvedLocalPetJson = await _localDb.getEntityById(
        table: LocalDbTables.pets,
        remoteId: resolvedPetId,
      );
      if (resolvedLocalPetJson != null) {
        return PetModel.fromJson(resolvedLocalPetJson);
      }
    }

    final apiPetId = resolvedPetId ?? trimmedPetId;
    try {
      final response = await _apiClient.get('$petsPath$apiPetId/');
      final json = jsonDecode(response.body);

      if (json is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected pet detail response from server.',
        );
      }

      await _persistPetMap(_asPetMap(json));
      return PetModel.fromJson(json);
    } catch (_) {
      rethrow;
    }
  }

  Future<PetModel> createPet(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        petsPath,
        body: jsonEncode(data),
        headers: const {'Content-Type': 'application/json'},
      );

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected create pet response from server.',
        );
      }

      final pet = PetModel.fromJson(json);
      await _persistPetMap(_asPetMap(json));
      await _invalidatePetsCache();
      return pet;
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final localId = _newLocalId('pet');
      final pendingPayload = _buildPendingPetPayload(
        source: data,
        petId: localId,
      );

      await _localDb.upsertEntity(
        table: LocalDbTables.pets,
        remoteId: localId,
        payload: pendingPayload,
        syncStatus: 'pending_create',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePet,
        entityId: localId,
        action: _actionCreate,
        payload: _asPetMap(data),
      );
      await _invalidatePetsCache();
      return PetModel.fromJson(pendingPayload);
    }
  }

  Future<PetModel> updatePet({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    final trimmedPetId = petId.trim();
    try {
      final response = await _apiClient.put(
        '$petsPath$trimmedPetId/',
        body: jsonEncode(data),
        headers: const {'Content-Type': 'application/json'},
      );

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected update pet response from server.',
        );
      }

      final pet = PetModel.fromJson(json);
      await _persistPetMap(_asPetMap(json), preservePendingLocal: false);
      await _invalidatePetsCache();
      return pet;
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.pets,
            remoteId: trimmedPetId,
          ) ??
          _buildPendingPetPayload(source: data, petId: trimmedPetId);

      final merged = <String, dynamic>{...current, ..._asPetMap(data)};
      merged['id'] = trimmedPetId;

      await _localDb.upsertEntity(
        table: LocalDbTables.pets,
        remoteId: trimmedPetId,
        payload: merged,
        syncStatus: 'pending_update',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePet,
        entityId: trimmedPetId,
        action: _actionUpdate,
        payload: _asPetMap(data),
      );
      await _invalidatePetsCache();
      return PetModel.fromJson(merged);
    }
  }

  Future<void> deletePet(String petId) async {
    final trimmedPetId = petId.trim();
    try {
      await _apiClient.delete('$petsPath$trimmedPetId/');
      await _localDb.deleteEntity(
        table: LocalDbTables.pets,
        remoteId: trimmedPetId,
      );
      await _invalidatePetsCache();
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      await _localDb.deleteEntity(
        table: LocalDbTables.pets,
        remoteId: trimmedPetId,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePet,
        entityId: trimmedPetId,
        action: _actionDelete,
      );
      await _invalidatePetsCache();
    }
  }

  Future<void> updatePetStatus({
    required String petId,
    required String status,
  }) async {
    await updatePet(petId: petId, data: <String, dynamic>{'status': status});
  }

  Future<void> addVaccination({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedPetId = petId.trim();
    try {
      final apiData = await _prepareVaccinationPayloadForApi(data);
      final response = await _apiClient.post(
        '$petsPath$normalizedPetId/vaccinations/',
        body: apiData,
      );

      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          await _persistVaccinationMap(
            _asPetMap(decoded),
            petId: normalizedPetId,
          );
        }
      }
      await _invalidatePetsCache();
    } catch (error) {
      if (!_shouldQueueOffline(error) &&
          !_shouldQueuePendingAttachmentResolution(error, data)) {
        rethrow;
      }

      final localVaccinationId = _newLocalId('vaccination');
      final pendingPayload = _buildPendingVaccinationPayload(
        source: data,
        petId: normalizedPetId,
        vaccinationId: localVaccinationId,
      );

      await _localDb.upsertEntity(
        table: LocalDbTables.petVaccinations,
        remoteId: localVaccinationId,
        payload: pendingPayload,
        syncStatus: 'pending_create',
      );
      await _upsertVaccinationIntoPetRow(
        petId: normalizedPetId,
        vaccinationJson: pendingPayload,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePetVaccination,
        entityId: localVaccinationId,
        action: _actionAddVaccination,
        payload: <String, dynamic>{
          'petId': normalizedPetId,
          'data': _asPetMap(data),
        },
      );
      await _invalidatePetsCache();
    }
  }

  Future<void> updateVaccination({
    required String petId,
    required String vaccinationId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedPetId = petId.trim();
    final normalizedVaccinationId = vaccinationId.trim();
    if (normalizedPetId.isEmpty || normalizedVaccinationId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing vaccination id.',
      );
    }

    try {
      final apiData = await _prepareVaccinationPayloadForApi(data);
      await _apiClient.put(
        '$petsPath$normalizedPetId/vaccinations/$normalizedVaccinationId/',
        body: apiData,
      );

      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.petVaccinations,
            remoteId: normalizedVaccinationId,
          ) ??
          <String, dynamic>{
            'id': normalizedVaccinationId,
            'petId': normalizedPetId,
          };
      final merged = <String, dynamic>{...current, ..._asPetMap(apiData)};
      merged['id'] = normalizedVaccinationId;
      merged['petId'] = normalizedPetId;
      await _localDb.upsertEntity(
        table: LocalDbTables.petVaccinations,
        remoteId: normalizedVaccinationId,
        payload: merged,
      );
      await _upsertVaccinationIntoPetRow(
        petId: normalizedPetId,
        vaccinationJson: merged,
      );
      await _invalidatePetsCache();
    } catch (error) {
      if (!_shouldQueueOffline(error) &&
          !_shouldQueuePendingAttachmentResolution(error, data)) {
        rethrow;
      }

      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.petVaccinations,
            remoteId: normalizedVaccinationId,
          ) ??
          _buildPendingVaccinationPayload(
            source: data,
            petId: normalizedPetId,
            vaccinationId: normalizedVaccinationId,
          );

      final merged = <String, dynamic>{...current, ..._asPetMap(data)};
      merged['id'] = normalizedVaccinationId;
      merged['petId'] = normalizedPetId;

      await _localDb.upsertEntity(
        table: LocalDbTables.petVaccinations,
        remoteId: normalizedVaccinationId,
        payload: merged,
        syncStatus: 'pending_update',
      );
      await _upsertVaccinationIntoPetRow(
        petId: normalizedPetId,
        vaccinationJson: merged,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePetVaccination,
        entityId: normalizedVaccinationId,
        action: _actionUpdateVaccination,
        payload: <String, dynamic>{
          'petId': normalizedPetId,
          'data': _asPetMap(data),
        },
      );
      await _invalidatePetsCache();
    }
  }

  Future<void> deleteVaccination({
    required String petId,
    required String vaccinationId,
  }) async {
    final normalizedPetId = petId.trim();
    final normalizedVaccinationId = vaccinationId.trim();
    try {
      await _apiClient.delete(
        '$petsPath$normalizedPetId/vaccinations/$normalizedVaccinationId/',
      );
      await _localDb.deleteEntity(
        table: LocalDbTables.petVaccinations,
        remoteId: normalizedVaccinationId,
      );
      await _invalidatePetsCache();
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      await _localDb.deleteEntity(
        table: LocalDbTables.petVaccinations,
        remoteId: normalizedVaccinationId,
      );
      await _removeVaccinationFromPetRow(
        petId: normalizedPetId,
        vaccinationId: normalizedVaccinationId,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityTypePetVaccination,
        entityId: normalizedVaccinationId,
        action: _actionDeleteVaccination,
        payload: <String, dynamic>{'petId': normalizedPetId},
      );
      await _invalidatePetsCache();
    }
  }

  Future<List<PetVaccinationModel>> getVaccinations(String petId) async {
    final normalizedPetId = petId.trim();
    try {
      final response = await _apiClient.get(
        '$petsPath$normalizedPetId/vaccinations/',
      );
      final json = jsonDecode(response.body);

      if (json is! List<dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected vaccinations response from server.',
        );
      }

      final maps = json.map(_asPetMap).toList(growable: false);
      await _persistVaccinationList(maps, petId: normalizedPetId);
      return maps.map(PetVaccinationModel.fromJson).toList(growable: false);
    } catch (_) {
      final localVaccinations = await _getVaccinationsFromLocalDb(
        normalizedPetId,
      );
      if (localVaccinations.isNotEmpty) {
        return localVaccinations;
      }
      rethrow;
    }
  }

  Future<PetVaccinationModel> getVaccination({
    required String petId,
    required String vaccinationId,
  }) async {
    final normalizedPetId = petId.trim();
    final normalizedVaccinationId = vaccinationId.trim();
    try {
      final response = await _apiClient.get(
        '$petsPath$normalizedPetId/vaccinations/$normalizedVaccinationId/',
      );
      final json = jsonDecode(response.body);

      if (json is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unexpected vaccination detail response from server.',
        );
      }

      await _persistVaccinationMap(_asPetMap(json), petId: normalizedPetId);
      return PetVaccinationModel.fromJson(json);
    } catch (_) {
      final localJson = await _localDb.getEntityById(
        table: LocalDbTables.petVaccinations,
        remoteId: normalizedVaccinationId,
      );
      if (localJson != null) {
        return PetVaccinationModel.fromJson(localJson);
      }
      rethrow;
    }
  }

  Future<void> markPetAsLost(String petId) async {
    await updatePetStatus(petId: petId, status: 'lost');
  }

  Future<void> markPetAsFound(String petId) async {
    await updatePetStatus(petId: petId, status: 'healthy');
  }

  Future<void> retryPendingSyncOperations({int limit = 30}) async {
    final petOperations = await _localDb.getPendingSyncOperations(
      entityType: _entityTypePet,
      limit: limit,
    );

    for (final operation in petOperations) {
      try {
        switch (operation.action) {
          case _actionCreate:
            final createPayload =
                operation.payload ?? const <String, dynamic>{};
            final response = await _apiClient.post(
              petsPath,
              body: jsonEncode(createPayload),
              headers: const {'Content-Type': 'application/json'},
            );
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              final remotePetId = _readPetRemoteId(_asPetMap(decoded));
              if (remotePetId != null && remotePetId.isNotEmpty) {
                await _localDb.setMetaValue(
                  key: '$_petIdMappingMetaPrefix${operation.entityId}',
                  value: remotePetId,
                );
              }
              await _localDb.deleteEntity(
                table: LocalDbTables.pets,
                remoteId: operation.entityId,
              );
              await _persistPetMap(_asPetMap(decoded));
            }
            break;
          case _actionUpdate:
            final petId = await _resolvePetIdForSync(operation.entityId);
            if (petId == null || petId.isEmpty) {
              throw const ApiException(
                type: ApiErrorType.unknown,
                message: 'Missing pet id in queued pet update operation.',
              );
            }

            final updatePayload = await _preparePetUpdatePayloadForApi(
              _asPetMap(operation.payload ?? const <String, dynamic>{}),
            );
            final response = await _apiClient.put(
              '$petsPath$petId/',
              body: jsonEncode(updatePayload),
              headers: const {'Content-Type': 'application/json'},
            );
            if (response.body.trim().isNotEmpty) {
              final decoded = jsonDecode(response.body);
              if (decoded is Map<String, dynamic>) {
                await _persistPetMap(
                  _asPetMap(decoded),
                  preservePendingLocal: false,
                );
              }
            }
            break;
          case _actionDelete:
            await _apiClient.delete('$petsPath${operation.entityId}/');
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

    final vaccinationOperations = await _localDb.getPendingSyncOperations(
      entityType: _entityTypePetVaccination,
      limit: limit,
    );

    for (final operation in vaccinationOperations) {
      try {
        final payload = operation.payload ?? const <String, dynamic>{};
        final queuedPetId = (payload['petId'] as String?)?.trim();
        final petId = await _resolvePetIdForSync(queuedPetId);
        if (petId == null || petId.isEmpty) {
          throw const ApiException(
            type: ApiErrorType.unknown,
            message: 'Missing petId in queued vaccination operation.',
          );
        }

        switch (operation.action) {
          case _actionAddVaccination:
            final addData = await _attachmentUploadService
                .resolvePendingAttachmentsInPayload(
                  _asPetMap(payload['data'] ?? const <String, dynamic>{}),
                );
            final response = await _apiClient.post(
              '$petsPath$petId/vaccinations/',
              body: addData,
            );
            if (response.body.trim().isNotEmpty) {
              final decoded = jsonDecode(response.body);
              if (decoded is Map<String, dynamic>) {
                await _localDb.deleteEntity(
                  table: LocalDbTables.petVaccinations,
                  remoteId: operation.entityId,
                );
                await _persistVaccinationMap(_asPetMap(decoded), petId: petId);
                await _removeVaccinationFromPetRow(
                  petId: petId,
                  vaccinationId: operation.entityId,
                );
                await _upsertVaccinationIntoPetRow(
                  petId: petId,
                  vaccinationJson: _asPetMap(decoded),
                );
              }
            }
            break;
          case _actionUpdateVaccination:
            final updateData = await _attachmentUploadService
                .resolvePendingAttachmentsInPayload(
                  _asPetMap(payload['data'] ?? const <String, dynamic>{}),
                );
            await _apiClient.put(
              '$petsPath$petId/vaccinations/${operation.entityId}/',
              body: updateData,
            );
            break;
          case _actionDeleteVaccination:
            await _apiClient.delete(
              '$petsPath$petId/vaccinations/${operation.entityId}/',
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

  List<PetModel> _parsePets(String body) {
    final json = jsonDecode(body);

    if (json is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected pets response from server.',
      );
    }

    return json.map(_asPetMap).map(PetModel.fromJson).toList(growable: false);
  }

  List<PetModel>? _tryParsePets(String body) {
    try {
      return _parsePets(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> _invalidatePetsCache() async {
    try {
      await _cache.clear(_petsCacheKey);
      await _cache.clear('users.current');
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  Map<String, dynamic> _asPetMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }

    return const <String, dynamic>{};
  }

  Future<void> _persistPetsFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List<dynamic>) {
        return;
      }

      for (final item in decoded) {
        await _persistPetMap(_asPetMap(item));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistPetMap(
    Map<String, dynamic> petJson, {
    bool preservePendingLocal = true,
  }) async {
    final remoteId = _readPetRemoteId(petJson);
    if (remoteId == null) {
      return;
    }

    if (preservePendingLocal) {
      final syncStatus = await _localDb.getEntitySyncStatus(
        table: LocalDbTables.pets,
        remoteId: remoteId,
      );
      if (_isPendingSyncStatus(syncStatus)) {
        return;
      }
    }

    await _localDb.upsertEntity(
      table: LocalDbTables.pets,
      remoteId: remoteId,
      payload: petJson,
    );
  }

  Future<List<PetModel>> _getPetsFromLocalDb() async {
    try {
      final localRows = await _localDb.getAllEntities(LocalDbTables.pets);
      return localRows.map(PetModel.fromJson).toList(growable: false);
    } catch (_) {
      return const <PetModel>[];
    }
  }

  Future<List<PetModel>> _mergeLocalPets(List<PetModel> pets) async {
    final localPets = await _getPetsFromLocalDb();
    if (localPets.isEmpty) {
      return pets;
    }

    final merged = <String, PetModel>{
      for (final pet in pets) pet.id: pet,
      for (final pet in localPets) pet.id: pet,
    };

    return merged.values.toList(growable: false);
  }

  String? _readPetRemoteId(Map<String, dynamic> petJson) {
    final id = petJson['id'] ?? petJson['_id'];
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

  Future<Map<String, dynamic>> _preparePetUpdatePayloadForApi(
    Map<String, dynamic> payload,
  ) async {
    final prepared = <String, dynamic>{...payload};
    if (_hasPendingPetPhotoUpload(prepared)) {
      final resolvedPhotoUrl = await _attachmentUploadService
          .resolvePendingUploadUrl(
            storagePath:
                (prepared[_photoStoragePathKey] as String?)?.trim() ?? '',
            localFilePath:
                (prepared[_photoLocalFilePathKey] as String?)?.trim() ?? '',
            fileName: (prepared[_photoFileNameKey] as String?)?.trim() ?? '',
            contentType:
                (prepared[_photoContentTypeKey] as String?)?.trim() ?? '',
          );
      prepared[_photoUrlKey] = resolvedPhotoUrl;
    }

    for (final key in _localPetPhotoSyncKeys) {
      prepared.remove(key);
    }
    return prepared;
  }

  bool _hasPendingPetPhotoUpload(Map<String, dynamic> payload) {
    final isPending = payload[_photoPendingUploadKey] == true;
    final storagePath =
        (payload[_photoStoragePathKey] as String?)?.trim() ?? '';
    final photoUrl = (payload[_photoUrlKey] as String?)?.trim() ?? '';
    return isPending || (photoUrl.isEmpty && storagePath.isNotEmpty);
  }

  List<String> get _localPetPhotoSyncKeys => const <String>[
    _photoPendingUploadKey,
    _photoStoragePathKey,
    _photoLocalFilePathKey,
    _photoFileNameKey,
    _photoContentTypeKey,
    _photoSizeBytesKey,
  ];

  bool _isPendingSyncStatus(String? syncStatus) {
    return syncStatus != null && syncStatus.startsWith('pending_');
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }

  bool _shouldQueuePendingAttachmentResolution(
    Object error,
    Map<String, dynamic> data,
  ) {
    final message = error.toString();
    return message.contains('Attachment upload still pending') &&
        _hasPendingAttachmentUpload(data);
  }

  bool _hasPendingAttachmentUpload(Map<String, dynamic> data) {
    final documents = data['attachedDocuments'];
    if (documents is! List) {
      return false;
    }

    return documents.map(_asPetMap).any((document) {
      return document['pendingUpload'] == true ||
          ((document['fileUri'] as String?)?.trim().isEmpty ?? true) &&
              ((document['storagePath'] as String?)?.trim().isNotEmpty ??
                  false);
    });
  }

  Future<Map<String, dynamic>> _prepareVaccinationPayloadForApi(
    Map<String, dynamic> data,
  ) async {
    final resolved = await _attachmentUploadService
        .resolvePendingAttachmentsInPayload(_asPetMap(data));
    return _sanitizeAttachmentPayloadForApi(resolved);
  }

  Map<String, dynamic> _sanitizeAttachmentPayloadForApi(
    Map<String, dynamic> payload,
  ) {
    final documents = payload['attachedDocuments'];
    if (documents is! List) {
      return payload;
    }

    return <String, dynamic>{
      ...payload,
      'attachedDocuments': documents
          .map(_sanitizeDocumentForApi)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _sanitizeDocumentForApi(dynamic value) {
    final document = _asPetMap(value);
    return <String, dynamic>{
      if ((document['documentId'] as String?)?.trim().isNotEmpty == true)
        'documentId': (document['documentId'] as String).trim(),
      'fileName': ((document['fileName'] as String?) ?? '').trim(),
      'fileUri': ((document['fileUri'] as String?) ?? '').trim(),
    };
  }

  String _newLocalId(String prefix) {
    return 'local_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _buildPendingPetPayload({
    required Map<String, dynamic> source,
    required String petId,
  }) {
    final map = _asPetMap(source);
    return <String, dynamic>{
      'id': petId,
      'schema': map['schema'] ?? 1,
      'owners': map['owners'] ?? const <dynamic>[],
      'name': map['name'] ?? '',
      'species': map['species'] ?? '',
      'breed': map['breed'] ?? '',
      'gender': map['gender'] ?? '',
      'birthDate': map['birthDate'] ?? map['birth_date'] ?? '',
      'weight': map['weight'],
      'color': map['color'] ?? '',
      'photoUrl': map['photoUrl'] ?? map['photo_url'],
      'status': map['status'] ?? 'healthy',
      'isNfcSynced': map['isNfcSynced'] ?? map['is_nfc_synced'] ?? false,
      'knownAllergies': map['knownAllergies'] ?? map['known_allergies'] ?? '',
      'defaultVet': map['defaultVet'] ?? map['default_vet'] ?? '',
      'defaultClinic': map['defaultClinic'] ?? map['default_clinic'] ?? '',
      'vaccinations': map['vaccinations'] ?? const <dynamic>[],
    };
  }

  Future<void> _persistVaccinationList(
    List<Map<String, dynamic>> vaccinations, {
    required String petId,
  }) async {
    for (final item in vaccinations) {
      await _persistVaccinationMap(item, petId: petId);
    }
  }

  Future<void> _persistVaccinationMap(
    Map<String, dynamic> vaccinationJson, {
    required String petId,
  }) async {
    final remoteId = _readVaccinationRemoteId(vaccinationJson);
    if (remoteId == null) {
      return;
    }

    final payload = <String, dynamic>{...vaccinationJson};
    payload['id'] = remoteId;
    payload['petId'] = petId;

    await _localDb.upsertEntity(
      table: LocalDbTables.petVaccinations,
      remoteId: remoteId,
      payload: payload,
    );
  }

  Future<void> _upsertVaccinationIntoPetRow({
    required String petId,
    required Map<String, dynamic> vaccinationJson,
  }) async {
    final petJson = await _localDb.getEntityById(
      table: LocalDbTables.pets,
      remoteId: petId,
    );

    if (petJson == null) {
      return;
    }

    final vaccinationId = _readVaccinationRemoteId(vaccinationJson);
    final currentVaccinations =
        (petJson['vaccinations'] as List<dynamic>?) ?? const <dynamic>[];
    final nextVaccinations = <Map<String, dynamic>>[];
    Map<String, dynamic>? existingVaccination;

    for (final item in currentVaccinations) {
      final itemMap = _asPetMap(item);
      if (vaccinationId != null && vaccinationId.isNotEmpty) {
        final currentId = _readVaccinationRemoteId(itemMap);
        if (currentId == vaccinationId) {
          existingVaccination = itemMap;
          continue;
        }
      }
      nextVaccinations.add(itemMap);
    }

    nextVaccinations.add({...?existingVaccination, ...vaccinationJson});

    await _localDb.upsertEntity(
      table: LocalDbTables.pets,
      remoteId: petId,
      payload: <String, dynamic>{...petJson, 'vaccinations': nextVaccinations},
    );
  }

  Future<void> _removeVaccinationFromPetRow({
    required String petId,
    required String vaccinationId,
  }) async {
    final petJson = await _localDb.getEntityById(
      table: LocalDbTables.pets,
      remoteId: petId,
    );

    if (petJson == null) {
      return;
    }

    final currentVaccinations =
        (petJson['vaccinations'] as List<dynamic>?) ?? const <dynamic>[];
    final nextVaccinations = currentVaccinations
        .map(_asPetMap)
        .where((item) => _readVaccinationRemoteId(item) != vaccinationId)
        .toList(growable: false);

    await _localDb.upsertEntity(
      table: LocalDbTables.pets,
      remoteId: petId,
      payload: <String, dynamic>{...petJson, 'vaccinations': nextVaccinations},
    );
  }

  Future<List<PetVaccinationModel>> _getVaccinationsFromLocalDb(
    String petId,
  ) async {
    try {
      final localRows = await _localDb.getAllEntities(
        LocalDbTables.petVaccinations,
      );
      final filtered = localRows.where((item) {
        final rowPetId = item['petId'];
        return rowPetId is String && rowPetId.trim() == petId;
      });

      return filtered.map(PetVaccinationModel.fromJson).toList(growable: false);
    } catch (_) {
      return const <PetVaccinationModel>[];
    }
  }

  String? _readVaccinationRemoteId(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['_id'] ?? json['vaccination_id'];
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

  Map<String, dynamic> _buildPendingVaccinationPayload({
    required Map<String, dynamic> source,
    required String petId,
    required String vaccinationId,
  }) {
    final map = _asPetMap(source);
    return <String, dynamic>{
      'id': vaccinationId,
      'petId': petId,
      'vaccineId': map['vaccineId'] ?? map['vaccine_id'] ?? '',
      'dateGiven': map['dateGiven'] ?? map['date_given'] ?? '',
      'nextDueDate': map['nextDueDate'] ?? map['next_due_date'] ?? '',
      'lotNumber': map['lotNumber'] ?? map['lot_number'] ?? '',
      'status': map['status'] ?? '',
      'administeredBy': map['administeredBy'] ?? map['administered_by'] ?? '',
      'clinicName': map['clinicName'] ?? map['clinic_name'] ?? '',
      'attachedDocuments':
          map['attachedDocuments'] ??
          map['attached_documents'] ??
          const <dynamic>[],
    };
  }
}
