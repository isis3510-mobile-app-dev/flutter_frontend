import 'dart:convert';

import 'package:flutter_frontend/core/models/event_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import '../network/api_client.dart';

class EventService {
  EventService._();

  static final EventService _instance = EventService._();

  factory EventService() => _instance;

  static const String eventsPath = '/api/events/';

  final ApiClient _apiClient = ApiClient();

  Future<List<EventModel>> getEventsByPet(String petId) async {
    final trimmedPetId = petId.trim();
    final encodedPetId = Uri.encodeQueryComponent(trimmedPetId);

    final response = await _apiClient.get('$eventsPath?pet_id=$encodedPetId');
    final decoded = _decodeJson(response.body);
    final eventItems = _extractEventItems(decoded);

    return eventItems
        .map(_asStringDynamicMap)
        .map(EventModel.fromJson)
        .toList(growable: false);
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await _apiClient.post(eventsPath, body: data);
    return _decodeEventMap(response.body, fallbackMessage: 'Unexpected create event response.');
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
    return _decodeEventMap(response.body, fallbackMessage: 'Unexpected update event response.');
  }

  Future<void> deleteEvent(String eventId) {
    return _apiClient.delete('$eventsPath${eventId.trim()}/');
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
      return decoded;
    }

    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Unexpected add event document response.',
    );
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
