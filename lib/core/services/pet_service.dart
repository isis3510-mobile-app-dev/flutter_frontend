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
