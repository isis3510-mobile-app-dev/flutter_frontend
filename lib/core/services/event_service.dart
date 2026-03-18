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

  Future<List<EventModel>> getEvents({String? petId, String? ownerId}) async {
    final queryParams = <String, String>{};

    final normalizedPetId = petId?.trim() ?? '';
    if (normalizedPetId.isNotEmpty) {
      queryParams['pet_id'] = normalizedPetId;
    }

    final normalizedOwnerId = ownerId?.trim() ?? '';
    if (normalizedOwnerId.isNotEmpty) {
      queryParams['owner_id'] = normalizedOwnerId;
    }

    final response = await _apiClient.get(
      _eventsPathWithQuery(queryParams),
    );
    final json = jsonDecode(response.body);
    final payload = _extractListPayload(json);

    return payload
        .map(_asEventMap)
        .map(EventModel.fromJson)
        .toList(growable: false);
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      eventsPath,
      body: jsonEncode(data),
      headers: const {'Content-Type': 'application/json'},
    );

    return _decodeEventMap(
      response.body,
      errorMessage: 'Unexpected create event response from server.',
    );
  }

  Future<EventModel> getEventById(String eventId) async {
    final response = await _apiClient.get(
      '$eventsPath${eventId.trim()}/',
    );

    return _decodeEventMap(
      response.body,
      errorMessage: 'Unexpected event detail response from server.',
    );
  }

  Future<EventModel> updateEvent({
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.put(
      '$eventsPath${eventId.trim()}/',
      body: jsonEncode(data),
      headers: const {'Content-Type': 'application/json'},
    );

    return _decodeEventMap(
      response.body,
      errorMessage: 'Unexpected update event response from server.',
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await _apiClient.delete('$eventsPath${eventId.trim()}/');
  }

  Future<void> addEventDocument({
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    await _apiClient.post(
      '$eventsPath${eventId.trim()}/documents/',
      body: jsonEncode(data),
      headers: const {'Content-Type': 'application/json'},
    );
  }

  String _eventsPathWithQuery(Map<String, String> queryParams) {
    if (queryParams.isEmpty) {
      return eventsPath;
    }

    final query = Uri(queryParameters: queryParams).query;
    return '$eventsPath?$query';
  }

  List<dynamic> _extractListPayload(dynamic json) {
    if (json is List<dynamic>) {
      return json;
    }

    if (json is Map<String, dynamic>) {
      final results = json['results'];
      if (results is List<dynamic>) {
        return results;
      }
    }

    throw const ApiException(
      type: ApiErrorType.unknown,
      message: 'Unexpected events response from server.',
    );
  }

  EventModel _decodeEventMap(String responseBody, {required String errorMessage}) {
    final json = jsonDecode(responseBody);
    if (json is! Map<String, dynamic>) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message: errorMessage,
      );
    }
    return EventModel.fromJson(json);
  }

  Map<String, dynamic> _asEventMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }

    return const <String, dynamic>{};
  }
}