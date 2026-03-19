import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../network/api_client.dart';
import 'user_service.dart';

class TelemetryService {
  TelemetryService._();

  static final TelemetryService _instance = TelemetryService._();

  factory TelemetryService() => _instance;

  static const String _featureExecutionLogsPath =
      '/api/feature-execution-logs/';
  static const String _featureClicksLogsPath = '/api/feature-clicks-logs/';

  static const String _envNfcReadFeatureId = 'FEATURE_NFC_READ_ID';
  static const String _envAddPetFeatureId = 'FEATURE_ADD_PET_ID';
  static const String _envAddEventRouteId = 'FEATURE_ROUTE_ADD_EVENT_ID';

  final ApiClient _apiClient = ApiClient();
  final UserService _userService = UserService();

  String? _cachedUserId;
  DateTime? _pendingAddPetStartTime;

  void startAddPetTimer() {
    _pendingAddPetStartTime = DateTime.now();
  }

  void cancelAddPetTimer() {
    _pendingAddPetStartTime = null;
  }

  Future<void> logNfcReadExecution({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final featureId = _readEnv(_envNfcReadFeatureId);
    if (featureId == null) {
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final totalTimeMs = endTime.difference(startTime).inMilliseconds;
    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'featureId': featureId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
    };

    try {
      await _apiClient.post(_featureExecutionLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<void> logAddPetExecutionIfPending({required DateTime endTime}) async {
    final startTime = _pendingAddPetStartTime;
    if (startTime == null) {
      return;
    }
    _pendingAddPetStartTime = null;

    final featureId = _readEnv(_envAddPetFeatureId);
    if (featureId == null) {
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final totalTimeMs = endTime.difference(startTime).inMilliseconds;
    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'featureId': featureId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
    };

    try {
      await _apiClient.post(_featureExecutionLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<void> logAddEventClick({int nClicks = 1}) async {
    final routeId = _readEnv(_envAddEventRouteId);
    if (routeId == null) {
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'routeId': routeId,
      'timestamp': DateTime.now().toIso8601String(),
      'nClicks': nClicks,
    };

    try {
      await _apiClient.post(_featureClicksLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<String?> _getUserId() async {
    final cached = _cachedUserId;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final user = await _userService.getCurrentUser();
      _cachedUserId = user.id;
      return user.id;
    } catch (_) {
      return null;
    }
  }

  String? _readEnv(String key) {
    try {
      final value = dotenv.env[key]?.trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }
}
