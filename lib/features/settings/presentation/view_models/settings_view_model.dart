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

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  static const String _darkModeKey = 'darkMode';
  static const String _notificationsKey = 'notificationsEnabled';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsViewModel() {
    _loadDarkModePreference();
    _loadNotificationPreference();
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
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      notifyListeners();

      await _syncNotificationWithFirebase();
    } catch (e) {
      print('Error loading notification preference: $e');
    }
  }

  Future<void> _syncNotificationWithFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final notificationSetting =
              userData?['notificationsEnabled'] as bool?;

          if (notificationSetting != null &&
              notificationSetting != _notificationsEnabled) {
            _notificationsEnabled = notificationSetting;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_notificationsKey, notificationSetting);

            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error syncing notification with Firebase: $e');
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
          await _enableNotifications();
        } else {
          final isLoggedIn = await AuthStatusService.isUserLoggedIn(user.uid);
          if (!isLoggedIn) {
            await _disableNotifications();
          } else {
            print(
              '⚠️ User is logged in, keeping FCM token for promotional notifications',
            );
          }
        }
      }
    } catch (e) {
      print('Error saving notification preference: $e');
      _notificationsEnabled = !value;
      notifyListeners();
    }
  }

  Future<void> _enableNotifications() async {
    try {
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        final granted = await _requestNotificationPermission();
        if (!granted) {
          print('⚠️ Notification permission not granted');
          return;
        }
      }

      final user = _auth.currentUser;
      if (user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _userService.saveFCMToken(user.uid, token);
          print('✅ FCM token saved after enabling notifications: $token');
        }
      }
    } catch (e) {
      print('❌ Error enabling notifications: $e');
    }
  }

  Future<void> _disableNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _userService.removeFCMToken(user.uid);
        print('✅ FCM token removed after disabling notifications');
      }
    } catch (e) {
      print('❌ Error disabling notifications: $e');
    }
  }

  Future<bool> _requestNotificationPermission() async {
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

      if (hasPermission && !_notificationsEnabled) {
        await toggleNotifications(true);
      } else if (!hasPermission && _notificationsEnabled) {
        await toggleNotifications(false);
      }
    } catch (e) {
      print('Error initializing notification settings: $e');
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
}
