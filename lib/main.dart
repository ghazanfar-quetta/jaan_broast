import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ADD THIS
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/onboarding/presentation/views/onboarding_screen.dart';
import 'features/auth/presentation/views/sign_up_screen.dart';
import 'features/splash/presentation/views/splash_screen.dart';
import 'features/home/presentation/views/home_screen.dart';
import 'features/home/presentation/view_models/home_view_model.dart';
import 'features/location/presentation/view_models/location_view_model.dart';
import 'features/settings/presentation/view_models/settings_view_model.dart';
import 'core/services/local_storage_service.dart';
import 'core/constants/app_themes.dart';
import 'features/favorites/presentation/view_models/favorites_view_model.dart';
import 'core/services/favorites_manager_service.dart';
import 'package:jaan_broast/core/services/firestore_cart_service.dart';
import 'features/cart/presentation/view_models/cart_view_model.dart';
import 'features/orders/presentation/view_models/order_view_model.dart';
import 'core/services/notification_service.dart';

// ADD THIS - Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Initialize NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Get and log FCM token
  final token = await notificationService.getFCMToken();
  print('🔔 Main - FCM Token: $token');
  print("🔔 Handling a background message: ${message.messageId}");

  if (message.notification != null) {
    print('🔔 Background Notification: ${message.notification!.title}');
    print('🔔 Background Notification Body: ${message.notification!.body}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permission on first app launch
  await _requestNotificationPermission();

  // Set portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  try {
    final hasAsked = await LocalStorageService.getNotificationPermissionAsked();

    if (!hasAsked) {
      // Use Firebase Messaging for permission
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
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

      // Get FCM token
      final token = await messaging.getToken();
      print('🔔 FCM Token: $token');

      // Mark as asked regardless of user's choice
      await LocalStorageService.setNotificationPermissionAsked(true);

      // Save token to SharedPreferences for initial use
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
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
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
        ChangeNotifierProvider(create: (_) => FavoritesViewModel()),
        ChangeNotifierProvider(create: (_) => FavoritesManagerService()),
        ChangeNotifierProvider<CartViewModel>(
          create: (context) => CartViewModel(FirestoreCartService()),
        ),
        ChangeNotifierProvider<OrderViewModel>(
          create: (context) => OrderViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsViewModel, child) {
          // Initialize notification settings when app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            //settingsViewModel.initializeNotificationSettings();
          });

          return MaterialApp(
            title: 'Jaan Broast',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settingsViewModel.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/auth': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
