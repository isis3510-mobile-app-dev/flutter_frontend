import 'dart:async';

import 'package:ambient_light/ambient_light.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { light, dark, schedule, sensor }

enum ThemeSource { manual, ambientLight, schedule }

class ThemeController extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  static const double _darkLuxThreshold = 18;
  static const double _lightLuxThreshold = 180;
  static const Duration _sensorPollingInterval = Duration(seconds: 4);
  static const int _requiredStableSensorReadings = 3;

  ThemeController();

  final AmbientLight _ambientLight = AmbientLight();

  bool _isInitialized = false;
  AppThemePreference _preference = AppThemePreference.schedule;
  Timer? _scheduleTimer;
  Timer? _sensorPollingTimer;
  StreamSubscription<double>? _ambientLightSubscription;
  bool? _sensorDarkMode;
  double? _lastAmbientLux;
  bool? _pendingSensorDarkMode;
  int _stableSensorReadingCount = 0;

  bool get isInitialized => _isInitialized;

  AppThemePreference get preference => _preference;

  ThemeSource get activeThemeSource => switch (_preference) {
    AppThemePreference.light => ThemeSource.manual,
    AppThemePreference.dark => ThemeSource.manual,
    AppThemePreference.schedule => ThemeSource.schedule,
    AppThemePreference.sensor =>
      _sensorDarkMode != null ? ThemeSource.ambientLight : ThemeSource.schedule,
  };

  double? get lastAmbientLux => _lastAmbientLux;

  ThemeMode get themeMode => switch (_preference) {
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
    AppThemePreference.schedule =>
      isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
    AppThemePreference.sensor =>
      isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
  };

  bool get isDarkModeEnabled => switch (_preference) {
    AppThemePreference.light => false,
    AppThemePreference.dark => true,
    AppThemePreference.schedule => _isWithinAutomaticDarkWindow(DateTime.now()),
    AppThemePreference.sensor =>
      _sensorDarkMode ?? _isWithinAutomaticDarkWindow(DateTime.now()),
  };

  bool get hasManualOverride =>
      _preference == AppThemePreference.light ||
      _preference == AppThemePreference.dark;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedPreference = prefs.getString(_themePreferenceKey);
    if (storedPreference != null) {
      _preference = AppThemePreference.values.firstWhere(
        (item) => item.name == storedPreference,
        orElse: () => AppThemePreference.schedule,
      );
    }

    _isInitialized = true;
    unawaited(_initializeAmbientLightMonitoring());
    _startAutomaticSchedule();
    _startSensorPolling();
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool isEnabled) async {
    await setPreference(
      isEnabled ? AppThemePreference.dark : AppThemePreference.light,
    );
  }

  Future<void> setPreference(AppThemePreference preference) async {
    _preference = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, preference.name);

    notifyListeners();
  }

  Future<void> clearManualOverride() async {
    await setPreference(AppThemePreference.schedule);
  }

  bool _isWithinAutomaticDarkWindow(DateTime now) {
    const defaultDarkStartHour = 18;
    const defaultDarkEndHour = 6;

    final hour = now.hour;
    final darkStartHour = defaultDarkStartHour;
    final darkEndHour = defaultDarkEndHour;

    if (darkStartHour == darkEndHour) {
      return true;
    }

    if (darkStartHour < darkEndHour) {
      return hour >= darkStartHour && hour < darkEndHour;
    }

    return hour >= darkStartHour || hour < darkEndHour;
  }

  Future<void> _initializeAmbientLightMonitoring() async {
    try {
      final initialLux = await _ambientLight.currentAmbientLight();
      _applyAmbientLightReading(initialLux);

      _ambientLightSubscription = _ambientLight.ambientLightStream.listen(
        _applyAmbientLightReading,
        onError: (_) {
          _sensorDarkMode = null;
          if (_preference == AppThemePreference.sensor) {
            notifyListeners();
          }
        },
      );
    } catch (_) {
      _sensorDarkMode = null;
      if (_preference == AppThemePreference.sensor) {
        notifyListeners();
      }
    }
  }

  void _applyAmbientLightReading(double? lux) {
    if (lux == null || lux.isNaN) {
      return;
    }

    _lastAmbientLux = lux;
    final previousMode = _sensorDarkMode;
    final fallbackMode =
        _sensorDarkMode ?? _isWithinAutomaticDarkWindow(DateTime.now());
    bool targetMode = fallbackMode;

    if (lux <= _darkLuxThreshold) {
      targetMode = true;
    } else if (lux >= _lightLuxThreshold) {
      targetMode = false;
    }

    if (_sensorDarkMode == null) {
      _sensorDarkMode = targetMode;
      _pendingSensorDarkMode = null;
      _stableSensorReadingCount = 0;
    } else if (targetMode == _sensorDarkMode) {
      _pendingSensorDarkMode = null;
      _stableSensorReadingCount = 0;
    } else {
      if (_pendingSensorDarkMode == targetMode) {
        _stableSensorReadingCount += 1;
      } else {
        _pendingSensorDarkMode = targetMode;
        _stableSensorReadingCount = 1;
      }

      if (_stableSensorReadingCount >= _requiredStableSensorReadings) {
        _sensorDarkMode = targetMode;
        _pendingSensorDarkMode = null;
        _stableSensorReadingCount = 0;
      }
    }

    if (_preference == AppThemePreference.sensor &&
        previousMode != _sensorDarkMode) {
      notifyListeners();
    }
  }

  void _startSensorPolling() {
    _sensorPollingTimer?.cancel();
    _sensorPollingTimer = Timer.periodic(_sensorPollingInterval, (_) async {
      if (_preference != AppThemePreference.sensor) {
        return;
      }

      try {
        final lux = await _ambientLight.currentAmbientLight();
        _applyAmbientLightReading(lux);
      } catch (_) {
        _sensorDarkMode = null;
        notifyListeners();
      }
    });
  }

  void _startAutomaticSchedule() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_preference != AppThemePreference.schedule &&
          _preference != AppThemePreference.sensor) {
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _sensorPollingTimer?.cancel();
    _ambientLightSubscription?.cancel();
    super.dispose();
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree.');
    return scope!.notifier!;
  }
}
