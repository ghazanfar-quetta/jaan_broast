// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS IMPORT
import '../services/local_storage_service.dart';

class AppRouter {
  static Future<String> getInitialRoute() async {
    try {
      // 1. FIRST check Firebase Auth - this is the source of truth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print(
        '👤 Firebase Auth check: ${firebaseUser != null ? "User logged in" : "No user"}',
      );

      // 2. Check if user has seen onboarding
      final hasSeenOnboarding =
          await LocalStorageService.getHasSeenOnboarding();
      print(
        '📱 Onboarding check: ${hasSeenOnboarding ? "Has seen" : "First time"}',
      );

      // 3. Check SharedPreferences for consistency
      final sharedPrefsLoggedIn = await LocalStorageService.getIsLoggedIn();
      print(
        '💾 SharedPreferences check: ${sharedPrefsLoggedIn ? "Logged in" : "Logged out"}',
      );

      // Fix inconsistency: If Firebase says no user but SharedPreferences says logged in
      if (firebaseUser == null && sharedPrefsLoggedIn) {
        print(
          '⚠️ Inconsistency detected: Clearing SharedPreferences login flag',
        );
        await LocalStorageService.setIsLoggedIn(false);
      }

      // 4. Now decide the route based on Firebase Auth
      if (!hasSeenOnboarding) {
        return '/onboarding';
      } else if (firebaseUser != null) {
        // User is actually logged in with Firebase
        return '/home';
      } else {
        // No Firebase user - go to auth
        return '/auth';
      }
    } catch (e) {
      print('❌ Error in AppRouter: $e');
      // Fallback: check SharedPreferences
      final hasSeenOnboarding =
          await LocalStorageService.getHasSeenOnboarding();
      final isLoggedIn = await LocalStorageService.getIsLoggedIn();

      if (!hasSeenOnboarding) {
        return '/onboarding';
      } else if (isLoggedIn) {
        return '/home';
      } else {
        return '/auth';
      }
    }
  }
}
