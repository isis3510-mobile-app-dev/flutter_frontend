import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../mappers/pet_mapper.dart';
import '../models/pet_ui_model.dart';

class PetsApiService {
  PetsApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<PetUiModel>> fetchPets() async {
    final response = await _client.getJson('/pets');
    final petsJson = _extractList(response);

    return petsJson
        .whereType<Map<String, dynamic>>()
        .map(PetMapper.fromJson)
        .toList();
  }

  Future<PetUiModel> fetchPetById(String id) async {
    final response = await _client.getJson('/pets/$id');
    final petJson = _extractItem(response);

    return PetMapper.fromJson(petJson);
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }

    if (response is Map<String, dynamic> && response['data'] is List<dynamic>) {
      return response['data'] as List<dynamic>;
    }

    throw const ApiException(
      message: 'Unexpected response format for pets list.',
    );
  }

  Map<String, dynamic> _extractItem(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }

    throw const ApiException(
      message: 'Unexpected response format for pet detail.',
    );
  }
}
