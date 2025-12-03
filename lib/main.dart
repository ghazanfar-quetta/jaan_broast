import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // IMPORTANT: Don't call Firebase.initializeApp() here anymore
  // The Flutter plugin handles this automatically

  print("🔄 Handling background message: ${message.messageId}");

  if (message.notification != null) {
    print('📱 Background Notification Title: ${message.notification!.title}');
    print('📱 Background Notification Body: ${message.notification!.body}');
  }

  // Process data payload if needed
  if (message.data.isNotEmpty) {
    print('📊 Background Message Data: ${message.data}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting app initialization...');

  // Set portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('📱 Portrait mode set');

  try {
    // Initialize Firebase with timeout
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Initialize background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background handler registered');

    // Initialize SharedPreferences
    print('💾 Initializing SharedPreferences...');
    await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized');

    // Setup notification handlers in foreground
    _setupFirebaseMessaging();

    // Request notification permissions (non-blocking)
    _requestNotificationPermissionInBackground();

    print('🎉 All initialization complete!');
  } catch (e, stackTrace) {
    print('❌ Initialization error: $e');
    print('📋 Stack trace: $stackTrace');
    print('⚠️ Continuing app launch without Firebase features...');
  }

  runApp(const MyApp());
}

void _setupFirebaseMessaging() {
  try {
    final messaging = FirebaseMessaging.instance;

    // Get token if already available
    messaging.getToken().then((token) {
      if (token != null) {
        print('🔑 Initial FCM Token: $token');
        _saveFcmToken(token);
      }
    });

    // Listen for token refresh
    messaging.onTokenRefresh.listen((token) {
      print('🔄 FCM Token refreshed: $token');
      _saveFcmToken(token);
    });

    // Handle messages when app is in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📲 Foreground message received!');
      print('📱 Message ID: ${message.messageId}');

      if (message.notification != null) {
        print('📢 Notification Title: ${message.notification!.title}');
        print('📢 Notification Body: ${message.notification!.body}');
      }

      // You can show a custom dialog or update UI here
      // The plugin automatically shows notifications when app is in background
    });

    // Handle when user taps on notification (app was in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 User tapped notification!');
      print('📱 Message ID: ${message.messageId}');

      // You can navigate to specific screen based on notification data
      if (message.data.isNotEmpty) {
        print('📊 Notification data: ${message.data}');
        // Example: Navigate to order details, chat, etc.
      }
    });

    // Get initial notification if app was launched from terminated state
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App launched from notification');
        print('📱 Initial Message ID: ${message.messageId}');

        // Handle navigation based on initial notification
        if (message.data.isNotEmpty) {
          print('📊 Initial notification data: ${message.data}');
        }
      }
    });

    print('✅ Firebase Messaging setup complete');
  } catch (e) {
    print('❌ Firebase Messaging setup error: $e');
  }
}

Future<void> _saveFcmToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    print('💾 FCM token saved to SharedPreferences');

    // Send token to your backend server if needed
    // await _sendTokenToServer(token);
  } catch (e) {
    print('❌ Failed to save FCM token: $e');
  }
}

void _requestNotificationPermissionInBackground() {
  // Delay permission request to avoid blocking app start
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      final hasAsked =
          await LocalStorageService.getNotificationPermissionAsked();

      if (!hasAsked) {
        print('🔔 Requesting notification permission...');

        final messaging = FirebaseMessaging.instance;

        // Request permission with basic options
        final NotificationSettings settings = await messaging.requestPermission(
          alert: true, // Show alerts
          badge: true, // Update app badge
          sound: true, // Play sound
          provisional: false, // Don't use provisional (quiet) permissions
        );

        print('🔔 Permission status: ${settings.authorizationStatus}');

        // Get token after permission
        if (settings.authorizationStatus != AuthorizationStatus.denied) {
          final token = await messaging.getToken();
          if (token != null) {
            print('🔑 Permission granted, FCM Token: $token');
            await _saveFcmToken(token);
          }
        }

        // Mark as asked
        await LocalStorageService.setNotificationPermissionAsked(true);
        print('✅ Notification permission flow complete');
      } else {
        print('🔔 Notification permission already asked');
      }
    } catch (e) {
      print('❌ Notification permission error: $e');
    }
  });
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
            // Optional: Initialize any notification-related settings
            // settingsViewModel.initializeNotificationSettings();
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
