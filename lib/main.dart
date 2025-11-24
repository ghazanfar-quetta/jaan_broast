import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your screens and view models
import 'features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/onboarding/presentation/views/onboarding_screen.dart';
import 'features/auth/presentation/views/sign_up_screen.dart';
import 'features/splash/presentation/views/splash_screen.dart';
import 'features/home/presentation/views/home_screen.dart';
import 'features/home/presentation/view_models/home_view_model.dart';
import 'features/location/presentation/view_models/location_view_model.dart'; // Add this import
import 'core/services/local_storage_service.dart';
import 'core/services/permission_service.dart';
import 'package:jaan_broast/routes.dart';
// Add this import for custom themes
import 'core/constants/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Request notification permission on first app launch
  await _requestNotificationPermission();
  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  try {
    final hasAsked = await LocalStorageService.getNotificationPermissionAsked();

    if (!hasAsked) {
      print('Requesting notification permission...');

      // Use the static method directly from PermissionService
      await PermissionService.requestNotificationPermission();

      // Mark as asked regardless of user's choice
      await LocalStorageService.setNotificationPermissionAsked(true);
      print('Notification permission flow completed');
    } else {
      print('Notification permission already asked');
    }
  } catch (e) {
    print('Error in notification permission flow: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(
          create: (_) => LocationViewModel(),
        ), // Add this line
      ],
      child: MaterialApp(
        title: 'Jaan Broast',
        theme: AppThemes.lightTheme, // Use our custom orange theme
        darkTheme: AppThemes.darkTheme, // Use our custom dark orange theme
        themeMode: ThemeMode.system, // Follow system theme
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
