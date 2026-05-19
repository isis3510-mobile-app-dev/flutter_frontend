import 'dart:convert';

import 'package:flutter_frontend/core/models/medicine_model.dart';
import 'package:flutter_frontend/core/network/api_client.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

class MedicineService {
  MedicineService._();

  static final MedicineService _instance = MedicineService._();
  factory MedicineService() => _instance;

  static const String medicinesPath = '/api/medicines/';

  final ApiClient _apiClient = ApiClient();

  Future<List<MedicineModel>> getMedicines({String? petId, String? ownerId}) async {
    final query = StringBuffer(medicinesPath);
    if (petId != null && petId.trim().isNotEmpty) {
      query.write('?pet_id=${Uri.encodeComponent(petId.trim())}');
    } else if (ownerId != null && ownerId.trim().isNotEmpty) {
      query.write('?owner_id=${Uri.encodeComponent(ownerId.trim())}');
    }

    try {
      final response = await _apiClient.get(query.toString());
      final body = response.body;
      final list = jsonDecode(body);
      if (list is! List<dynamic>) {
        throw const ApiException(type: ApiErrorType.unknown, message: 'Unexpected medicines response.');
      }

      return list.map((e) => MedicineModel.fromJson(_asMap(e))).toList(growable: false);
    } catch (_) {
      rethrow;
    }
  }

  Future<List<MedicineModel>> getMedicinesForPets(List<String> petIds) async {
    final results = <MedicineModel>[];
    for (final petId in petIds) {
      try {
        final medicines = await getMedicines(petId: petId);
        results.addAll(medicines);
      } catch (_) {
        // ignore failures for individual pets
      }
    }
    return results;
  }

  Map<String, dynamic> _asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return item.map((k, v) => MapEntry(k.toString(), v));
    return const <String, dynamic>{};
  }
}
