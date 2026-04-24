import '../network/api_client.dart';
import '../telemetry/telemetry_ids.dart';
import 'user_service.dart';

class TelemetryService {
  TelemetryService._();

  static final TelemetryService _instance = TelemetryService._();

  factory TelemetryService() => _instance;

  static const String _featureExecutionLogsPath =
      '/api/feature-execution-logs/';
  static const String _featureClicksLogsPath = '/api/feature-clicks-logs/';
  static const String _screenTimeLogsPath = '/api/screen-time-logs/';

  final ApiClient _apiClient = ApiClient();
  final UserService _userService = UserService();

  String? _cachedUserId;
  DateTime? _pendingAddPetStartTime;
  int _pendingAddPetUploadBytes = 0;
  int _pendingAddPetDownloadBytes = 0;
  String? _pendingAddPetFeatureId;

  void startAddPetTimer({required String featureId}) {
    if (featureId.trim().isEmpty) {
      return;
    }
    _pendingAddPetStartTime = DateTime.now();
    _pendingAddPetUploadBytes = 0;
    _pendingAddPetDownloadBytes = 0;
    _pendingAddPetFeatureId = featureId;
  }

  void cancelAddPetTimer() {
    _pendingAddPetStartTime = null;
    _pendingAddPetUploadBytes = 0;
    _pendingAddPetDownloadBytes = 0;
    _pendingAddPetFeatureId = null;
  }

  void addAddPetNetworkBytes({
    required int uploadBytes,
    required int downloadBytes,
  }) {
    _pendingAddPetUploadBytes += uploadBytes;
    _pendingAddPetDownloadBytes += downloadBytes;
  }

  Future<void> logNfcReadExecution({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (featureNfcReadId.isEmpty) {
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
      'featureId': featureNfcReadId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
      'appType' : "Flutter"
    };

    try {
      await _apiClient.post(_featureExecutionLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<void> logAddPetExecutionIfPending({required DateTime endTime}) async {
    final startTime = _pendingAddPetStartTime;
    final featureId = _pendingAddPetFeatureId;
    if (startTime == null) {
      return;
    }
    _pendingAddPetStartTime = null;

    if (featureId == null || featureId.isEmpty) {
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final totalTimeMs = endTime.difference(startTime).inMilliseconds;
    final totalSeconds = totalTimeMs <= 0 ? 0 : totalTimeMs / 1000.0;
    final uploadSpeed = totalSeconds == 0
        ? 0
        : (_pendingAddPetUploadBytes / totalSeconds).round();
    final downloadSpeed = totalSeconds == 0
        ? 0
        : (_pendingAddPetDownloadBytes / totalSeconds).round();

    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'featureId': featureId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
      'uploadSpeed': uploadSpeed,
      'downloadSpeed': downloadSpeed,
      'appType' : "Flutter"
    };

    try {
      await _apiClient.post(_featureExecutionLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }

    _pendingAddPetUploadBytes = 0;
    _pendingAddPetDownloadBytes = 0;
    _pendingAddPetFeatureId = null;
  }

  Future<void> logAddEventClick({int nClicks = 1}) async {
    if (featureRouteAddEventId.isEmpty) {
      return;
    }

    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'routeId': featureRouteAddEventId,
      'timestamp': DateTime.now().toIso8601String(),
      'nClicks': nClicks,
      'appType' : "Flutter"
    };

    try {
      await _apiClient.post(_featureClicksLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<void> logScreenTime({
    required String screenId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final userId = await _getUserId();
    if (userId == null) {
      return;
    }

    final totalTimeMs = endTime.difference(startTime).inMilliseconds;
    final payload = <String, dynamic>{
      'schema': 1,
      'userId': userId,
      'screenId': screenId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
      'appType' : "Flutter"
    };

    try {
      await _apiClient.post(_screenTimeLogsPath, body: payload);
    } catch (_) {
      // Telemetry should never block the UI or crash the app.
    }
  }

  Future<void> logCachedPetProfileLoadExecution({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (featureLoadCachedPetProfileId.isEmpty) {
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
      'featureId': featureLoadCachedPetProfileId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalTime': totalTimeMs,
      'downloadSpeed': 0,
      'uploadSpeed': 0,
      'appType': 'Flutter',
    };

    try {
      await _apiClient.post(_featureExecutionLogsPath, body: payload);
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

  // Telemetry IDs are sourced from lib/core/telemetry/telemetry_ids.dart.
}
