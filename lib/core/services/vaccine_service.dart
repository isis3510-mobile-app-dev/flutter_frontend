import 'dart:async';
import 'dart:convert';

import 'package:flutter_frontend/core/models/vaccine_model.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';

import '../network/api_client.dart';
import 'local_database_service.dart';
import 'response_cache_service.dart';

class VaccineService {
  VaccineService._();

  static final VaccineService _instance = VaccineService._();
  factory VaccineService() => _instance;

  static const String vaccinesPath = '/api/vaccines/';
  static const String _vaccinesCacheKey = 'vaccines.catalog';
  static const String _vaccineByIdCachePrefix = 'vaccines.byId.';
  static const Duration _vaccinesCacheTtl = Duration(hours: 12);
  static const Duration _vaccineByIdCacheTtl = Duration(hours: 12);

  final ApiClient _apiClient = ApiClient();
  final ResponseCacheService _cache = ResponseCacheService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  Future<List<VaccineModel>> getVaccines({bool forceRefresh = false}) async {
    final cachedEntry = await _cache.get(_vaccinesCacheKey);
    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_vaccinesCacheTtl)) {
      final cachedVaccines = _tryParseVaccines(cachedEntry.body);
      if (cachedVaccines != null) {
        unawaited(_persistVaccinesFromBody(cachedEntry.body));
        return cachedVaccines;
      }
    }

    try {
      final response = await _apiClient.get(vaccinesPath);
      final vaccines = _parseVaccines(response.body);
      await _cache.set(_vaccinesCacheKey, response.body);
      await _persistVaccinesFromBody(response.body);
      return vaccines;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackVaccines = _tryParseVaccines(cachedEntry.body);
        if (fallbackVaccines != null) {
          unawaited(_persistVaccinesFromBody(cachedEntry.body));
          return fallbackVaccines;
        }
      }

      final localVaccines = await _getVaccinesFromLocalDb();
      if (localVaccines.isNotEmpty) {
        return localVaccines;
      }
      rethrow;
    }
  }

  Future<VaccineModel> getVaccineById(
    String vaccineId, {
    bool forceRefresh = false,
  }) async {
    final normalizedVaccineId = vaccineId.trim();
    final cacheKey = _vaccineByIdCacheKey(normalizedVaccineId);
    final cachedEntry = await _cache.get(cacheKey);

    if (!forceRefresh && cachedEntry != null && cachedEntry.isFresh(_vaccineByIdCacheTtl)) {
      final cachedVaccine = _tryParseVaccine(cachedEntry.body);
      if (cachedVaccine != null) {
        return cachedVaccine;
      }
    }

    try {
      final response = await _apiClient.get('$vaccinesPath$normalizedVaccineId/');
      final vaccine = _parseVaccine(response.body);
      await _cache.set(cacheKey, response.body);
      await _persistVaccineMap(_asVaccineMap(jsonDecode(response.body)));
      return vaccine;
    } catch (_) {
      if (cachedEntry != null) {
        final fallbackVaccine = _tryParseVaccine(cachedEntry.body);
        if (fallbackVaccine != null) {
          unawaited(_persistVaccineFromBody(cachedEntry.body));
          return fallbackVaccine;
        }
      }

      final localVaccineJson = await _localDb.getEntityById(
        table: LocalDbTables.vaccines,
        remoteId: normalizedVaccineId,
      );
      if (localVaccineJson != null) {
        return VaccineModel.fromJson(localVaccineJson);
      }
      rethrow;
    }
  }

  List<VaccineModel> _parseVaccines(String body) {
    final json = jsonDecode(body);

    if (json is! List<dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccines response from server.',
      );
    }

    return json.map(_asVaccineMap).map(VaccineModel.fromJson).toList(growable: false);
  }

  List<VaccineModel>? _tryParseVaccines(String body) {
    try {
      return _parseVaccines(body);
    } catch (_) {
      return null;
    }
  }

  VaccineModel _parseVaccine(String body) {
    final json = jsonDecode(body);

    if (json is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Unexpected vaccine detail response from server.',
      );
    }

    return VaccineModel.fromJson(json);
  }

  VaccineModel? _tryParseVaccine(String body) {
    try {
      return _parseVaccine(body);
    } catch (_) {
      return null;
    }
  }

  String _vaccineByIdCacheKey(String vaccineId) {
    return '$_vaccineByIdCachePrefix$vaccineId';
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

  Future<void> _persistVaccinesFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List<dynamic>) {
        return;
      }

      for (final item in decoded) {
        await _persistVaccineMap(_asVaccineMap(item));
      }
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistVaccineFromBody(String body) async {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      await _persistVaccineMap(decoded);
    } catch (_) {
      // Local persistence is best effort.
    }
  }

  Future<void> _persistVaccineMap(Map<String, dynamic> vaccineJson) async {
    final remoteId = _readRemoteId(vaccineJson);
    if (remoteId == null) {
      return;
    }

    await _localDb.upsertEntity(
      table: LocalDbTables.vaccines,
      remoteId: remoteId,
      payload: vaccineJson,
    );
  }

  Future<List<VaccineModel>> _getVaccinesFromLocalDb() async {
    try {
      final localRows = await _localDb.getAllEntities(LocalDbTables.vaccines);
      return localRows.map(VaccineModel.fromJson).toList(growable: false);
    } catch (_) {
      return const <VaccineModel>[];
    }
  }

  String? _readRemoteId(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['_id'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is Map) {
      final oid = raw['\$oid'];
      if (oid is String && oid.trim().isNotEmpty) {
        return oid.trim();
      }
    }

    return null;
  }
}