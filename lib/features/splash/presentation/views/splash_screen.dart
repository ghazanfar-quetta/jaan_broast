// lib/features/splash/presentation/views/splash_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../routes.dart';
import '../../../../core/services/permission_service.dart'; // Add this import
import '../../../../core/services/local_storage_service.dart'; // Add this import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Keep the 2-second delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Get the initial route from your existing AppRouter
    final initialRoute = await AppRouter.getInitialRoute();

    // Check if we should ask for notification permission
    // Only ask if this is the first time (user hasn't seen onboarding)
    final hasSeenOnboarding = await LocalStorageService.getHasSeenOnboarding();

    if (!hasSeenOnboarding) {
      // First app launch - FORCE show permission dialog
      // Don't check permission status, just show it
      _showNotificationPermissionDialog(initialRoute);
      return; // Don't navigate yet, dialog will handle it
    }

    // If not first launch, proceed normally
    if (mounted) {
      AppRoutes.pushReplacement(context, initialRoute);
    }
  }

  void _showNotificationPermissionDialog(String nextRoute) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enable Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Stay updated with order status, special offers, and important updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        // In _showNotificationPermissionDialog method
        actions: [
          TextButton(
            onPressed: () async {
              // User chose "Not Now" - mark as NOT allowed
              await LocalStorageService.setUserAllowedNotification(false);
              await LocalStorageService.setNotificationPermissionAsked(true);
              Navigator.pop(context);
              if (mounted) {
                AppRoutes.pushReplacement(context, nextRoute);
              }
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              // User chose "Allow"
              await PermissionService.requestNotificationPermission();
              // Also mark as user allowed
              await LocalStorageService.setUserAllowedNotification(true);
              Navigator.pop(context);
              if (mounted) {
                AppRoutes.pushReplacement(context, nextRoute);
              }
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash/splash_image.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
