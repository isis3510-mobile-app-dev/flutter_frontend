import 'dart:convert';

import '../models/smart_alert_model.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class SmartFeatureService {
  SmartFeatureService._();

  static final SmartFeatureService _instance = SmartFeatureService._();

  factory SmartFeatureService() => _instance;

  static const String _petsPath = '/api/pets/';

  final ApiClient _apiClient = ApiClient();

  Future<PetSmartSuggestionsModel> getPetSmartSuggestions(String petId) async {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Missing pet id for smart suggestions.',
      );
    }

    final response = await _apiClient.get('$_petsPath$normalizedPetId/smart/');
    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected smart suggestions response from server.',
      );
    }

    final parsed = PetSmartSuggestionsModel.fromJson(json);
    return parsed.copyWith(
      petId: parsed.petId.trim().isEmpty ? normalizedPetId : parsed.petId,
    );
  }
}
