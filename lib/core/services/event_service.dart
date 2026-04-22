import 'dart:async';
import 'dart:convert';

import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import '../network/api_client.dart';
import 'local_database_service.dart';
import 'response_cache_service.dart';

class EventService {
  EventService._();

  static final EventService _instance = EventService._();

  factory EventService() => _instance;

  static const String eventsPath = '/api/events/';
  static const String _eventsByPetCachePrefix = 'events.byPet.';
  static const Duration _eventsByPetCacheTtl = Duration(minutes: 5);
  static const String _entityType = 'event';
  static const String _actionCreate = 'create';
  static const String _actionUpdate = 'update';
  static const String _actionDelete = 'delete';

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<List<EventModel>> getEventsByPet(
    String petId, {
    bool forceRefresh = false,
  }) async {
    final trimmedPetId = petId.trim();
    final cacheKey = _eventsByPetCacheKey(trimmedPetId);
    final cachedEntry = await _cache.get(cacheKey);

    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_eventsByPetCacheTtl)) {
      final cachedEvents = _tryParseEvents(cachedEntry.body);
      if (cachedEvents != null) {
        unawaited(_persistEventsFromBody(cachedEntry.body));
        return cachedEvents;
      }
    }

    final encodedPetId = Uri.encodeQueryComponent(trimmedPetId);

    try {
      final response = await _apiClient.get('$eventsPath?pet_id=$encodedPetId');
      final events = _parseEvents(response.body);
      await _cache.set(cacheKey, response.body);
      await _persistEventsFromBody(response.body);
      return events;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackEvents = _tryParseEvents(cachedEntry.body);
        if (fallbackEvents != null) {
          unawaited(_persistEventsFromBody(cachedEntry.body));
          return fallbackEvents;
        }
      }

      final localEvents = await _getEventsByPetFromLocalDb(trimmedPetId);
      if (localEvents.isNotEmpty) {
        return localEvents;
      }
      rethrow;
    }
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(eventsPath, body: data);
      final createdEvent = _decodeEventMap(
        response.body,
        fallbackMessage: 'Unexpected create event response.',
      );
      await _persistEventMap(_eventToMap(createdEvent));
      await _invalidateEventsCache();
      return createdEvent;
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final localId = _newLocalId('event');
      final pendingPayload = _buildPendingEventPayload(
        source: data,
        eventId: localId,
      );

      await _localDb.upsertEntity(
        table: LocalDbTables.events,
        remoteId: localId,
        payload: pendingPayload,
        syncStatus: 'pending_create',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: localId,
        action: _actionCreate,
        payload: _asStringDynamicMap(data),
      );
      await _invalidateEventsCache();
      return EventModel.fromJson(pendingPayload);
    }
  }

  Future<EventModel> getEventById(String eventId) async {
    final trimmedEventId = eventId.trim();
    try {
      final response = await _apiClient.get('$eventsPath$trimmedEventId/');
      final event = _decodeEventMap(
        response.body,
        fallbackMessage: 'Unexpected event detail response.',
      );
      await _persistEventMap(_eventToMap(event));
      return event;
    } catch (_) {
      final localEventJson = await _localDb.getEntityById(
        table: LocalDbTables.events,
        remoteId: trimmedEventId,
      );
      if (localEventJson != null) {
        return EventModel.fromJson(localEventJson);
      }
      rethrow;
    }
  }

  Future<EventModel> updateEvent({
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    final trimmedEventId = eventId.trim();
    try {
      final response = await _apiClient.put(
        '$eventsPath$trimmedEventId/',
        body: data,
      );
      final updatedEvent = _decodeEventMap(
        response.body,
        fallbackMessage: 'Unexpected update event response.',
      );
      await _persistEventMap(_eventToMap(updatedEvent));
      await _invalidateEventsCache();
      return updatedEvent;
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      final current =
          await _localDb.getEntityById(
            table: LocalDbTables.events,
            remoteId: trimmedEventId,
          ) ??
          _buildPendingEventPayload(source: data, eventId: trimmedEventId);

      final merged = <String, dynamic>{...current, ..._asStringDynamicMap(data)};
      merged['id'] = trimmedEventId;

      await _localDb.upsertEntity(
        table: LocalDbTables.events,
        remoteId: trimmedEventId,
        payload: merged,
        syncStatus: 'pending_update',
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedEventId,
        action: _actionUpdate,
        payload: _asStringDynamicMap(data),
      );
      await _invalidateEventsCache();
      return EventModel.fromJson(merged);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final trimmedEventId = eventId.trim();
    try {
      await _apiClient.delete('$eventsPath$trimmedEventId/');
      await _localDb.deleteEntity(
        table: LocalDbTables.events,
        remoteId: trimmedEventId,
      );
      await _invalidateEventsCache();
    } catch (error) {
      if (!_shouldQueueOffline(error)) {
        rethrow;
      }

      await _localDb.deleteEntity(
        table: LocalDbTables.events,
        remoteId: trimmedEventId,
      );
      await _localDb.enqueueSyncOperation(
        entityType: _entityType,
        entityId: trimmedEventId,
        action: _actionDelete,
      );
      await _invalidateEventsCache();
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
            final createPayload = operation.payload ?? const <String, dynamic>{};
            final response = await _apiClient.post(
              eventsPath,
              body: createPayload,
            );
            final created = _decodeEventMap(
              response.body,
              fallbackMessage: 'Unexpected create event response.',
            );
            await _localDb.deleteEntity(
              table: LocalDbTables.events,
              remoteId: operation.entityId,
            );
            await _persistEventMap(_eventToMap(created));
            break;
          case _actionUpdate:
            await _apiClient.put(
              '$eventsPath${operation.entityId}/',
              body: operation.payload ?? const <String, dynamic>{},
            );
            break;
          case _actionDelete:
            await _apiClient.delete('$eventsPath${operation.entityId}/');
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

  Future<Map<String, dynamic>> addEventDocument({
    required String eventId,
    required Map<String, dynamic> documentData,
  }) async {
    final response = await _apiClient.post(
      '$eventsPath${eventId.trim()}/documents/',
      body: documentData,
    );

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      await _invalidateEventsCache();
      return decoded;
    }

    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Unexpected add event document response.',
    );
  }

  List<EventModel> _parseEvents(String responseBody) {
    final decoded = _decodeJson(responseBody);
    final eventItems = _extractEventItems(decoded);

    return eventItems
        .map(_asStringDynamicMap)
        .map(EventModel.fromJson)
        .toList(growable: false);
  }

  List<EventModel>? _tryParseEvents(String responseBody) {
    try {
      return _parseEvents(responseBody);
    } catch (_) {
      return null;
    }
  }

  Future<void> _invalidateEventsCache() async {
    try {
      await _cache.clearByPrefix(_eventsByPetCachePrefix);
    } catch (_) {
      // Cache invalidation is best effort.
    }
  }

  String _eventsByPetCacheKey(String petId) {
    return '$_eventsByPetCachePrefix$petId';
  }

  EventModel _decodeEventMap(String responseBody, {required String fallbackMessage}) {
    final decoded = _decodeJson(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message: fallbackMessage,
      );
    }

    return EventModel.fromJson(decoded);
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }

  List<dynamic> _extractEventItems(dynamic decoded) {
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
      message: 'Unexpected events response from server.',
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

  Future<void> _persistEventsFromBody(String responseBody) async {
    try {
      final decoded = _decodeJson(responseBody);
      final items = _extractEventItems(decoded);
      for (final item in items) {
        await _persistEventMap(_asStringDynamicMap(item));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistEventMap(Map<String, dynamic> eventJson) async {
    final remoteId = _readRemoteId(eventJson);
    if (remoteId == null) {
      return;
    }

    await _localDb.upsertEntity(
      table: LocalDbTables.events,
      remoteId: remoteId,
      payload: eventJson,
    );
  }

  Future<List<EventModel>> _getEventsByPetFromLocalDb(String petId) async {
    try {
      final events = await _localDb.getAllEntities(LocalDbTables.events);
      final filtered = events.where((eventJson) {
        final localPetId = _readPetId(eventJson);
        return localPetId != null && localPetId == petId;
      });
      return filtered.map(EventModel.fromJson).toList(growable: false);
    } catch (_) {
      return const <EventModel>[];
    }
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

  String? _readPetId(Map<String, dynamic> json) {
    final raw = json['petId'] ?? json['pet_id'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is Map) {
      final oid = raw['\$oid'];
      if (oid is String && oid.trim().isNotEmpty) {
        return oid.trim();
      }

      final nestedId = raw['id'] ?? raw['_id'];
      if (nestedId is String && nestedId.trim().isNotEmpty) {
        return nestedId.trim();
      }
    }

    return null;
  }

  Map<String, dynamic> _eventToMap(EventModel event) {
    return <String, dynamic>{
      'id': event.id,
      'schema': event.schema,
      'petId': event.petId,
      'ownerId': event.ownerId,
      'title': event.title,
      'eventType': event.eventType,
      'date': event.date.toIso8601String(),
      'price': event.price,
      'provider': event.provider,
      'clinic': event.clinic,
      'description': event.description,
      'followUpDate': event.followUpDate?.toIso8601String(),
      'attachedDocuments': event.attachedDocuments
          .map(
            (doc) => <String, dynamic>{
              'documentId': doc.documentId,
              'fileName': doc.fileName,
              'fileUri': doc.fileUri,
            },
          )
          .toList(growable: false),
    };
  }

  bool _shouldQueueOffline(Object error) {
    return error is ApiException && error.type == ApiErrorType.network;
  }

  String _newLocalId(String prefix) {
    return 'local_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _buildPendingEventPayload({
    required Map<String, dynamic> source,
    required String eventId,
  }) {
    final map = _asStringDynamicMap(source);
    return <String, dynamic>{
      'id': eventId,
      'schema': map['schema'] ?? 1,
      'petId': map['petId'] ?? map['pet_id'] ?? '',
      'ownerId': map['ownerId'] ?? map['owner_id'] ?? '',
      'title': map['title'] ?? '',
      'eventType': map['eventType'] ?? map['event_type'] ?? 'general',
      'date': map['date'] ?? DateTime.now().toIso8601String(),
      'price': map['price'],
      'provider': map['provider'] ?? '',
      'clinic': map['clinic'] ?? '',
      'description': map['description'] ?? '',
      'followUpDate': map['followUpDate'] ?? map['follow_up_date'],
      'attachedDocuments': map['attachedDocuments'] ??
          map['attached_documents'] ??
          const <dynamic>[],
    };
  }
}
