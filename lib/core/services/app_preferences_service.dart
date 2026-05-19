import 'package:flutter_frontend/app/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  AppPreferencesService._();

  static final AppPreferencesService _instance = AppPreferencesService._();

  factory AppPreferencesService() => _instance;

  static const String _themePreferenceKey = 'app_preferences.theme_preference';
  static const String _notificationsEnabledKey =
      'app_preferences.notifications_enabled';
  static const String _dismissedLostPetNotificationsKey =
      'app_preferences.dismissed_lost_pet_notifications';
  static const String _hasSeenWelcomeKey = 'app_preferences.has_seen_welcome';

  Future<AppThemePreference?> getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPreference = prefs.getString(_themePreferenceKey);
    if (storedPreference == null || storedPreference.trim().isEmpty) {
      return null;
    }

    return AppThemePreference.values.firstWhere(
      (item) => item.name == storedPreference,
      orElse: () => AppThemePreference.schedule,
    );
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, value.name);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<Set<String>> getDismissedLostPetNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dismissedLostPetNotificationsKey) ??
            const <String>[])
        .where((id) => id.trim().isNotEmpty)
        .toSet();
  }

  Future<void> setDismissedLostPetNotificationIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dismissedLostPetNotificationsKey,
      ids.toList(growable: false),
    );
  }

  Future<bool> getHasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenWelcomeKey) ?? false;
  }

  Future<void> setHasSeenWelcome(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, value);
  }
}
