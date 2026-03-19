import 'dart:convert';

import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import '../network/api_client.dart';
import 'response_cache_service.dart';

class EventService {
  EventService._();

  static final EventService _instance = EventService._();

  factory EventService() => _instance;

  static const String eventsPath = '/api/events/';
  static const String _eventsByPetCachePrefix = 'events.byPet.';
  static const Duration _eventsByPetCacheTtl = Duration(minutes: 5);

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();

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
        return cachedEvents;
      }
    }

    final encodedPetId = Uri.encodeQueryComponent(trimmedPetId);

    try {
      final response = await _apiClient.get('$eventsPath?pet_id=$encodedPetId');
      final events = _parseEvents(response.body);
      await _cache.set(cacheKey, response.body);
      return events;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackEvents = _tryParseEvents(cachedEntry.body);
        if (fallbackEvents != null) {
          return fallbackEvents;
        }
      }
      rethrow;
    }
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await _apiClient.post(eventsPath, body: data);
    final createdEvent = _decodeEventMap(
      response.body,
      fallbackMessage: 'Unexpected create event response.',
    );
    await _invalidateEventsCache();
    return createdEvent;
  }

  Future<EventModel> getEventById(String eventId) async {
    final response = await _apiClient.get('$eventsPath${eventId.trim()}/');
    return _decodeEventMap(response.body, fallbackMessage: 'Unexpected event detail response.');
  }

  Future<EventModel> updateEvent({
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.put(
      '$eventsPath${eventId.trim()}/',
      body: data,
    );
    final updatedEvent = _decodeEventMap(
      response.body,
      fallbackMessage: 'Unexpected update event response.',
    );
    await _invalidateEventsCache();
    return updatedEvent;
  }

  Future<void> deleteEvent(String eventId) async {
    await _apiClient.delete('$eventsPath${eventId.trim()}/');
    await _invalidateEventsCache();
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
}
