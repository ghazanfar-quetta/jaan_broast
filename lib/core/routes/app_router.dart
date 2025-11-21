// lib/core/routes/app_router.dart
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class AppRouter {
  static Future<String> getInitialRoute() async {
    final hasSeenOnboarding = await LocalStorageService.getHasSeenOnboarding();
    final isLoggedIn = await LocalStorageService.getIsLoggedIn();

    if (!hasSeenOnboarding) {
      return '/onboarding';
    } else if (isLoggedIn) {
      return '/home'; // You'll create this later
    } else {
      return '/auth';
    }
  }
}
