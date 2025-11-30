import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS IMPORT

class SettingsViewModel with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _darkModeKey = 'darkMode';
  final FirebaseAuth _auth = FirebaseAuth.instance; // ADD THIS

  bool get isDarkMode => _isDarkMode;

  SettingsViewModel() {
    _loadDarkModePreference();
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
