// lib/core/services/fcm_token_manager.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jaan_broast/core/services/notification_service.dart';
import 'package:jaan_broast/core/services/user_service.dart';

class FCMTokenManager {
  static final NotificationService _notificationService = NotificationService();
  static final UserService _userService = UserService();

  // Call this when user successfully logs in
  static Future<void> onUserLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
          '🔔 Getting and saving FCM token after login for user: ${user.uid}',
        );

        // Ensure user document exists
        await _userService.createOrUpdateUserDocument(user);

        // Get and save FCM token
        final token = await _notificationService.getAndSaveFCMToken();

        if (token != null) {
          print('✅ FCM token saved after login: $token');
        } else {
          print('⚠️ Could not get FCM token after login');
        }
      }
    } catch (e) {
      print('❌ Error saving FCM token after login: $e');
    }
  }

  // Call this when user logs out
  static Future<void> onUserLogout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔔 Removing FCM token after logout for user: ${user.uid}');

        // Remove FCM token using UserService
        await _userService.removeFCMToken(user.uid);

        // Also remove from notification service
        await _notificationService.removeFCMToken();

        print('✅ FCM token removed after logout');
      }
    } catch (e) {
      print('❌ Error removing FCM token after logout: $e');
    }
  }

  // Check and update FCM token on app startup if user is logged in
  static Future<void> checkAndUpdateToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔔 User is logged in, checking FCM token for: ${user.uid}');

        // Ensure user document exists
        await _userService.createOrUpdateUserDocument(user);

        // Get and save FCM token
        final token = await _notificationService.getAndSaveFCMToken();

        if (token != null) {
          print('✅ FCM token updated on app start: $token');
        }
      }
    } catch (e) {
      print('❌ Error checking/updating FCM token: $e');
    }
  }
}
