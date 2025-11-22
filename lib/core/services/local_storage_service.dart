// lib/core/services/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _permissionsAskedKey = 'permissions_asked';
  static const String _notificationPermissionAskedKey =
      'notification_permission_asked';

  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, value);
  }

  static Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setIsLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  static Future<bool> getIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Add these new methods for permissions
  static Future<void> setPermissionsAsked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsAskedKey, value);
  }

  static Future<bool> getPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsAskedKey) ?? false;
  }

  static Future<void> setNotificationPermissionAsked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionAskedKey, value);
  }

  static Future<bool> getNotificationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermissionAskedKey) ?? false;
  }
}
