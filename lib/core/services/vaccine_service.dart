import 'dart:convert';

import 'package:flutter_frontend/core/models/vaccine_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import '../network/api_client.dart';

class VaccineService {
  VaccineService._();

  static final VaccineService _instance = VaccineService._();
  factory VaccineService() => _instance;

  static const String vaccinesPath = '/api/vaccines/';

  final ApiClient _apiClient = ApiClient();
  
  Future<List<VaccineModel>> getVaccines() async {
    final response = await _apiClient.get(vaccinesPath);
    final json = jsonDecode(response.body);

    if (json is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccines response from server.',
      );
    }

    return json.map(_asVaccineMap).map(VaccineModel.fromJson).toList(growable: false);
  }

  Future<VaccineModel> getVaccineById(String vaccineId) async {
    final response = await _apiClient.get('$vaccinesPath$vaccineId/');
    final json = jsonDecode(response.body);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccine detail response from server.',
      );
    }

    return VaccineModel.fromJson(json);
  }

  Map<String, dynamic> _asVaccineMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }

    return const <String, dynamic>{};
  }
}