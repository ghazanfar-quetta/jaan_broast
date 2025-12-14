// lib/core/utils/notification_navigator.dart
import 'package:flutter/material.dart';

class NotificationNavigator {
  // Remove 'final' to make it assignable
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Navigate to any screen
  static void navigateToScreen(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
    } else {
      print('⚠️ Navigator key not ready for route: $routeName');
    }
  }

  // Navigate to order details
  static void navigateToOrderDetails(String orderId) {
    // Note: You'll need to create this route in your app
    // For now, navigate to home with orderId
    navigateToScreen(
      '/home',
      arguments: {'orderId': orderId, 'showOrderDetails': true},
    );
  }

  // Navigate to home screen
  static void navigateToHome() {
    navigateToScreen('/home');
  }
}
