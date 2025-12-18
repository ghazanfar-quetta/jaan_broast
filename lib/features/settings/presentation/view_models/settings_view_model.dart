// lib/features/settings/presentation/view_models/settings_view_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart'; // ADD THIS IMPORT
import '../../../../core/services/user_service.dart';
import 'package:jaan_broast/core/services/auth_status_service.dart';
import 'package:jaan_broast/features/auth/presentation/view_models/auth_view_model.dart'; // ADD THIS IMPORT
import 'package:jaan_broast/core/services/local_storage_service.dart';

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  static const String _darkModeKey = 'darkMode';
  static const String _notificationsKey = 'notificationsEnabled';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  SettingsViewModel() {
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    _isLoading = false;
  }

  Future<void> _loadPreferences() async {
    await _loadDarkModePreference();
    await _loadNotificationPreference();
  }

  Future<void> _loadDarkModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading dark mode preference: $e');
    }
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First check if user was ever asked for permission
      final hasSetPreference =
          await LocalStorageService.getHasSetNotificationPreference();
      final onboardingPreference =
          await LocalStorageService.getOnboardingNotificationPreference();

      if (hasSetPreference && onboardingPreference != null) {
        // User was asked and made a choice
        _notificationsEnabled = onboardingPreference;
        print(
          '🔔 Using user\'s notification preference: $_notificationsEnabled',
        );

        // Also save to regular preferences for consistency
        await prefs.setBool(_notificationsKey, onboardingPreference);
      } else if (hasSetPreference && onboardingPreference == null) {
        // User was asked but preference is null (edge case)
        _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
        print('ℹ️ No preference saved, using false as default');
      } else {
        // User was never asked - default to FALSE (not true)
        _notificationsEnabled = false;
        print('ℹ️ User never asked for permission - default to FALSE');
      }

      // Sync with Firebase
      await _syncWithFirebaseIfNeeded();
    } catch (e) {
      print('Error loading notification preference: $e');
      _notificationsEnabled = false; // Default to false on error
    }
  }

  Future<void> _syncWithFirebaseIfNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final firebaseSetting = userData?['notificationsEnabled'] as bool?;

          // If Firebase has a different setting, update local storage
          if (firebaseSetting != null &&
              firebaseSetting != _notificationsEnabled) {
            print(
              '🔄 Syncing with Firebase notification setting: $firebaseSetting',
            );
            _notificationsEnabled = firebaseSetting;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_notificationsKey, firebaseSetting);

            // Also update onboarding preference if not set
            final hasSetPreference =
                await LocalStorageService.getHasSetNotificationPreference();
            if (!hasSetPreference) {
              await LocalStorageService.setOnboardingNotificationPreference(
                firebaseSetting,
              );
              await LocalStorageService.setHasSetNotificationPreference(true);
            }
          }
        }
      }
    } catch (e) {
      print('Error syncing with Firebase: $e');
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
    } catch (e) {
      print('Error saving dark mode preference: $e');
    }
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    if (_notificationsEnabled == value) return;

    // If trying to enable notifications
    if (value) {
      final hasPermission = await checkNotificationPermission();

      if (!hasPermission) {
        print('🔔 No permission - requesting notification permission...');

        // Request permission (this shows system dialog)
        final granted = await requestNotificationPermission();

        if (!granted) {
          print('❌ User denied permission - keeping toggle OFF');
          // Don't change the toggle - keep it OFF
          return;
        }

        print('✅ Permission granted - proceeding with enabling notifications');
      }
    }

    // Only reach here if:
    // 1. We're turning OFF notifications, OR
    // 2. We're turning ON and have permission

    _notificationsEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'notificationsEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (value) {
          // Now enable notifications (we have permission)
          await _enableNotificationsWithToken();
        } else {
          await _disableNotifications();
          await _unsubscribeFromAllTopics();
        }
      }
    } catch (e) {
      print('Error saving notification preference: $e');
      _notificationsEnabled = !value;
      notifyListeners();
    }
  }

  // Update the enable method to actually get/save token
  Future<void> _enableNotificationsWithToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get FCM token (should work since we have permission)
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _userService.saveFCMToken(user.uid, token);
          print('✅ FCM token saved: $token');
        }

        // Subscribe to topics
        try {
          await _subscribeToUserTopics(user.uid);
        } catch (e) {
          print('⚠️ Could not subscribe to topics: $e');
        }
      }
    } catch (e) {
      print('❌ Error enabling notifications: $e');
    }
  }

  // Add this method
  Future<void> _subscribeToUserTopics(String userId) async {
    try {
      // Subscribe to general topics
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('order_updates');

      // Subscribe to user-specific topic
      await _firebaseMessaging.subscribeToTopic('user_$userId');

      print('✅ Subscribed to topics for user: $userId');
    } catch (e) {
      print('❌ Error subscribing to topics: $e');
    }
  }

  Future<void> _disableNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Remove FCM token from your Firestore
        await _userService.removeFCMToken(user.uid);

        // 2. Delete the FCM token from Firebase instance (IMPORTANT!)
        await _firebaseMessaging.deleteToken();

        // 3. Unsubscribe from all topics
        await _firebaseMessaging.unsubscribeFromTopic('all_users');
        await _firebaseMessaging.unsubscribeFromTopic('user_${user.uid}');

        print('✅ FCM token deleted and unsubscribed from all topics');
      }
    } catch (e) {
      print('❌ Error disabling notifications: $e');
    }
  }

  // Add this method
  Future<void> _unsubscribeFromAllTopics() async {
    try {
      // Unsubscribe from common topics
      final topics = ['all_users', 'promotions', 'order_updates'];
      for (final topic in topics) {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      }

      // Unsubscribe from user-specific topic
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseMessaging.unsubscribeFromTopic('user_${user.uid}');
      }

      print('✅ Unsubscribed from all topics');
    } catch (e) {
      print('❌ Error unsubscribing from topics: $e');
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
        '🔔 Notification permission status: ${settings.authorizationStatus}',
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _userService.saveFCMToken(user.uid, token);
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> _removeFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _userService.removeFCMToken(user.uid);
      }
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  Future<void> initializeNotificationSettings() async {
    try {
      final hasPermission = await checkNotificationPermission();
      final user = _auth.currentUser;

      if (user != null) {
        // Get current Firestore setting
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final firebaseSetting = userData?['notificationsEnabled'] as bool?;

          // Sync with local setting
          if (firebaseSetting != null &&
              firebaseSetting != _notificationsEnabled) {
            print('🔄 Syncing notification setting with Firebase');
            await toggleNotifications(firebaseSetting);
          }
        }
      }

      // If no permission, ensure notifications are off
      if (!hasPermission && _notificationsEnabled) {
        print('⚠️ No notification permission, disabling notifications');
        await toggleNotifications(false);
      }
    } catch (e) {
      print('Error initializing notification settings: $e');
    }
  }

  Future<bool> areNotificationsActuallyDisabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      // Check Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return true;

      final userData = userDoc.data();
      final notificationsEnabled = userData?['notificationsEnabled'] as bool?;

      // Check local preference
      final prefs = await SharedPreferences.getInstance();
      final localEnabled = prefs.getBool(_notificationsKey) ?? true;

      // Both should be false for notifications to be actually disabled
      return (notificationsEnabled == false) && (localEnabled == false);
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  // FIXED: Simple logout method that doesn't try to manage auth state
  // In SettingsViewModel.dart - Replace the logout method with this:

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Update Firestore
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await AuthStatusService.setUserLoggedOut(user.uid);
        } catch (e) {
          print('⚠️ Firestore update failed: $e');
        }
      }

      // 2. Firebase signout
      await _auth.signOut();

      // 3. Clear local storage (you need to import LocalStorageService)
      // await LocalStorageService.setIsLoggedIn(false);

      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      // ALWAYS navigate away
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth', // Make sure this is your correct login route
          (route) => false,
        );
      }
    }
  }

  Future<void> reloadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      notifyListeners();
      print('🔄 SettingsViewModel reloaded: $_notificationsEnabled');
    } catch (e) {
      print('Error reloading notification preference: $e');
    }
  }
}
