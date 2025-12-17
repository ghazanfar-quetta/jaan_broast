// lib/core/services/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _permissionsAskedKey = 'permissions_asked';
  static const String _notificationPermissionAskedKey =
      'notification_permission_asked';

  // Add these methods to your existing LocalStorageService class

  // Check if user has logged in before
  static Future<bool> getHasLoggedInBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_logged_in_before') ?? false;
  }

  // Set that user has logged in before
  static Future<void> setHasLoggedInBefore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in_before', value);
  }

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
  // Add to LocalStorageService class in lib/core/services/local_storage_service.dart

  // Favorites caching
  static Future<void> cacheFavorites(List<String> foodItemIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_favorites', foodItemIds);
  }

  static Future<List<String>> getCachedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('cached_favorites') ?? [];
  }

  static Future<void> addToCachedFavorites(String foodItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = await getCachedFavorites();
    if (!currentFavorites.contains(foodItemId)) {
      currentFavorites.add(foodItemId);
      await prefs.setStringList('cached_favorites', currentFavorites);
    }
  }

  static Future<void> removeFromCachedFavorites(String foodItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = await getCachedFavorites();
    currentFavorites.remove(foodItemId);
    await prefs.setStringList('cached_favorites', currentFavorites);
  }

  // Add this to LocalStorageService class
  static Future<void> setNotificationPermissionStatus(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_permission_granted', granted);
  }

  static Future<bool> getNotificationPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_permission_granted') ?? false;
  }

  // Add to LocalStorageService class if not already present
  static Future<void> setUserAllowedNotification(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_allowed_notification', allowed);
  }

  static Future<bool> getUserAllowedNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_allowed_notification') ?? false;
  }
}
