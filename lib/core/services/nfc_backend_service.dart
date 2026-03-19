import 'dart:convert';

import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

class NfcBackendService {
  NfcBackendService._();

  static final NfcBackendService _instance = NfcBackendService._();

  factory NfcBackendService() => _instance;

  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> readPublicTagData(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing pet id to read NFC data.',
      );
    }

    final response = await _apiClient.get(
      '/api/nfc/read/$normalizedPetId/',
      authenticated: false,
    );

    return _decodeRequiredMap(
      response.body,
      fallbackMessage: 'Unexpected NFC read response from server.',
    );
  }

  Future<Map<String, dynamic>> getWritePayload(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing pet id to build NFC payload.',
      );
    }

    final response = await _apiClient.get('/api/pets/$normalizedPetId/nfc-payload/');

    return _decodeRequiredMap(
      response.body,
      fallbackMessage: 'Unexpected NFC payload response from server.',
    );
  }

  Future<Map<String, dynamic>> syncPet(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing pet id to sync NFC status.',
      );
    }

    final response = await _apiClient.post('/api/pets/$normalizedPetId/nfc-sync/');
    return _decodeOptionalMap(response.body);
  }

  Map<String, dynamic> _decodeRequiredMap(
    String body, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeOptionalMap(body);
    if (decoded.isNotEmpty) {
      return decoded;
    }

    throw ApiException(
      type: ApiErrorType.unknown,
      message: fallbackMessage,
    );
  }

  Map<String, dynamic> _decodeOptionalMap(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return const <String, dynamic>{};
  }
}
