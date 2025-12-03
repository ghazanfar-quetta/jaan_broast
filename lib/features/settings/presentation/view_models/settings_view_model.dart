// lib/features/settings/presentation/view_models/settings_view_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/services/user_service.dart'; // ADD THIS

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  static const String _darkModeKey = 'darkMode';
  static const String _notificationsKey = 'notificationsEnabled';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService(); // ADD THIS

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

  // Load notification preference
  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      notifyListeners();

      // Also check Firebase for the setting
      await _syncNotificationWithFirebase();
    } catch (e) {
      print('Error loading notification preference: $e');
    }
  }

  // Sync with Firebase
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

            // Update local storage
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

  // Toggle notifications
  Future<void> toggleNotifications(bool value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);

      // Save to Firebase
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'notificationsEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Handle FCM token based on preference
        if (value) {
          // Only save token if enabling, don't request permission
          await _saveFCMToken();
        } else {
          // Remove token when disabling
          await _removeFCMToken();
        }
      }
    } catch (e) {
      print('Error saving notification preference: $e');
      _notificationsEnabled = !value;
      notifyListeners();
    }
  }

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
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

      print('Notification permission status: ${settings.authorizationStatus}');

      // If permission denied, update setting
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _notificationsEnabled = false;
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationsKey, false);
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  // Save FCM token
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

  // Remove FCM token
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

  // Check notification permission
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

  // Initialize notification settings on app start
  Future<void> initializeNotificationSettings() async {
    try {
      // Check current permission status
      final hasPermission = await checkNotificationPermission();

      // If user has permission but setting is false, update it
      if (hasPermission && !_notificationsEnabled) {
        await toggleNotifications(true);
      }
      // If user doesn't have permission but setting is true, update it
      else if (!hasPermission && _notificationsEnabled) {
        await toggleNotifications(false);
      }
    } catch (e) {
      print('Error initializing notification settings: $e');
    }
  }

  // Updated logout method with Firebase Auth integration
  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();
      print('User logged out successfully');

      // Navigate to auth screen and clear navigation stack
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/auth', (Route<dynamic> route) => false);
    } catch (e) {
      print('Error during logout: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
