import 'dart:convert';

import '../models/pet_model.dart';
import '../network/api_exception.dart';
import '../network/api_client.dart';
import 'response_cache_service.dart';

class PetService {
  PetService._();

  static final PetService _instance = PetService._();

  factory PetService() => _instance;

  static const String petsPath = '/api/pets/';
  static const String myPetsPath = '/api/pets/mine';
  static const String _petsCacheKey = 'pets.mine';
  static const Duration _petsCacheTtl = Duration(minutes: 5);

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();

  Future<List<PetModel>> getPets({bool forceRefresh = false}) async {
    final cachedEntry = await _cache.get(_petsCacheKey);
    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_petsCacheTtl)) {
      final cachedPets = _tryParsePets(cachedEntry.body);
      if (cachedPets != null) {
        return cachedPets;
      }
    }

    try {
      final response = await _apiClient.get(myPetsPath);
      final pets = _parsePets(response.body);
      await _cache.set(_petsCacheKey, response.body);
      return pets;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackPets = _tryParsePets(cachedEntry.body);
        if (fallbackPets != null) {
          return fallbackPets;
        }
      }
      rethrow;
    }
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

    final pet = PetModel.fromJson(json);
    await _invalidatePetsCache();
    return pet;
  }

  Future<PetModel> updatePet({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.put(
      '$petsPath${petId.trim()}/',
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
    await _invalidatePetsCache();
    return pet;
  }

  Future<void> deletePet(String petId) async {
    await _apiClient.delete('$petsPath${petId.trim()}/');
    await _invalidatePetsCache();
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
    await _invalidatePetsCache();
  }

  Future<void> addVaccination({
    required String petId,
    required Map<String, dynamic> data,
  }) async {
    await _apiClient.post('$petsPath$petId/vaccinations/', body: data);
    await _invalidatePetsCache();
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

    await _apiClient.put(
      '$petsPath$normalizedPetId/vaccinations/$normalizedVaccinationId/',
      body: data,
    );
    await _invalidatePetsCache();
  }

  Future<void> deleteVaccination({
    required String petId,
    required String vaccinationId,
  }) async {
    await _apiClient.delete('$petsPath$petId/vaccinations/$vaccinationId/');
    await _invalidatePetsCache();
  }

  Future<List<PetVaccinationModel>> getVaccinations(String petId) async {
    final response = await _apiClient.get('$petsPath$petId/vaccinations/');
    final json = jsonDecode(response.body);

    if (json is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccinations response from server.',
      );
    }

    return json
        .map(_asPetMap)
        .map(PetVaccinationModel.fromJson)
        .toList(growable: false);
  }

  Future<PetVaccinationModel> getVaccination({
    required String petId,
    required String vaccinationId,
  }) async {
    final response = await _apiClient.get(
      '$petsPath$petId/vaccinations/$vaccinationId/',
    );
    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccination detail response from server.',
      );
    }

    return PetVaccinationModel.fromJson(json);
  }

  Future<void> markPetAsLost(String petId) async {
    await updatePetStatus(petId: petId, status: 'lost');
  }

  Future<void> markPetAsFound(String petId) async {
    await updatePetStatus(petId: petId, status: 'healthy');
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
      // Invalidate both the pets list cache and the user profile cache
      // since the user profile contains the list of pets
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
}
