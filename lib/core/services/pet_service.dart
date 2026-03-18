import 'dart:convert';

import '../models/pet_model.dart';
import '../network/api_exception.dart';
import '../network/api_client.dart';

class PetService {
  PetService._();

  static final PetService _instance = PetService._();

  factory PetService() => _instance;

  static const String petsPath = '/api/pets/';

  final ApiClient _apiClient = ApiClient();

  Future<List<PetModel>> getPets() async {
    final response = await _apiClient.get(petsPath);
    final json = jsonDecode(response.body);

    if (json is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected pets response from server.',
      );
    }

    return json.map(_asPetMap).map(PetModel.fromJson).toList(growable: false);
  }

  Future<PetModel> getPetById(String petId) async {
    final response = await _apiClient.get('$petsPath$petId/');
    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected pet detail response from server.',
      );
    }
    return PetModel.fromJson(json);
  }

  Future<PetModel> createPet(Map<String, dynamic> data) async {
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

    return PetModel.fromJson(json);
  }

  Future<void> updatePetStatus({
    required String petId,
    required String status,
  }) async {
    await _apiClient.put(
      '$petsPath$petId/',
      body: jsonEncode({'status': status}),
      headers: const {'Content-Type': 'application/json'},
    );
  }

  Future<void> addVaccination({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    await _apiClient.post(
      '$petsPath$petId/vaccinations/',
      body: data,
    );
  }

  Future<void> updateVaccination({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    await _apiClient.put(
      '$petsPath$petId/vaccinations/',
      body: data,
    );
  }

  Future<void> deleteVaccination({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    await _apiClient.delete(
      '$petsPath$petId/vaccinations/',
      body: data,
    );
  }

  Future<void> markPetAsLost(String petId) async {
    await updatePetStatus(petId: petId, status: 'lost');
  }

  Future<void> markPetAsFound(String petId) async {
    await updatePetStatus(petId: petId, status: 'healthy');
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
}
