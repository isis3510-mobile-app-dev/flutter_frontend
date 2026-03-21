import 'package:flutter/material.dart';

import '../services/telemetry_service.dart';
import 'screen_ids.dart';

class ScreenTimeObserver extends NavigatorObserver {
  final Map<Route<dynamic>, _ScreenSession> _sessions = {};
  final TelemetryService _telemetryService = TelemetryService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _startSession(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _endSession(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _endSession(oldRoute);
    }
    if (newRoute != null) {
      _startSession(newRoute);
    }
  }

  void _startSession(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    final screenId = screenIdByRoute[name];
    if (screenId == null || screenId.isEmpty) {
      return;
    }

    _sessions[route] = _ScreenSession(
      screenId: screenId,
      startTime: DateTime.now(),
    );
  }

  void _endSession(Route<dynamic> route) {
    final session = _sessions.remove(route);
    if (session == null) {
      return;
    }
    _telemetryService.logScreenTime(
      screenId: session.screenId,
      startTime: session.startTime,
      endTime: DateTime.now(),
    );
  }
}

class _ScreenSession {
  const _ScreenSession({
    required this.screenId,
    required this.startTime,
  });

  final String screenId;
  final DateTime startTime;
}
