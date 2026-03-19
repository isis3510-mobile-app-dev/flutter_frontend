import 'dart:convert';

import '../models/smart_alert_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'response_cache_service.dart';

class SmartFeatureService {
  SmartFeatureService._();

  static final SmartFeatureService _instance = SmartFeatureService._();

  factory SmartFeatureService() => _instance;

  static const String _petsPath = '/api/pets/';
  static const String _smartSuggestionsCachePrefix = 'smartSuggestions.pet.';
  static const Duration _smartSuggestionsCacheTtl = Duration(minutes: 5);

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();

  Future<PetSmartSuggestionsModel> getPetSmartSuggestions(
    String petId, {
    bool forceRefresh = false,
  }) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing pet id for smart suggestions.',
      );
    }

    final cacheKey = _smartSuggestionsCacheKey(normalizedPetId);
    final cachedEntry = await _cache.get(cacheKey);

    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_smartSuggestionsCacheTtl)) {
      final cachedSuggestions = _tryParseSmartSuggestions(
        cachedEntry.body,
        fallbackPetId: normalizedPetId,
      );
      if (cachedSuggestions != null) {
        return cachedSuggestions;
      }
    }

    try {
      final response = await _apiClient.get('$_petsPath$normalizedPetId/smart/');
      final suggestions = _parseSmartSuggestions(
        response.body,
        fallbackPetId: normalizedPetId,
      );
      await _cache.set(cacheKey, response.body);
      return suggestions;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackSuggestions = _tryParseSmartSuggestions(
          cachedEntry.body,
          fallbackPetId: normalizedPetId,
        );
        if (fallbackSuggestions != null) {
          return fallbackSuggestions;
        }
      }
      rethrow;
    }
  }

  PetSmartSuggestionsModel _parseSmartSuggestions(
    String responseBody, {
    required String fallbackPetId,
  }) {
    final json = jsonDecode(responseBody);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected smart suggestions response from server.',
      );
    }

    final parsed = PetSmartSuggestionsModel.fromJson(json);
    return parsed.copyWith(
      petId: parsed.petId.trim().isEmpty ? fallbackPetId : parsed.petId,
    );
  }

  PetSmartSuggestionsModel? _tryParseSmartSuggestions(
    String responseBody, {
    required String fallbackPetId,
  }) {
    try {
      return _parseSmartSuggestions(responseBody, fallbackPetId: fallbackPetId);
    } catch (_) {
      return null;
    }
  }

  String _smartSuggestionsCacheKey(String petId) {
    return '$_smartSuggestionsCachePrefix$petId';
  }
}
