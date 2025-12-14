import 'package:jaan_broast/core/services/fcm_token_manager.dart';
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
import 'core/utils/notification_navigator.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔄 Handling background message: ${message.messageId}");

  // Initialize notification service
  await NotificationService().initialize();

  if (message.notification != null) {
    print('📱 Background Notification Title: ${message.notification!.title}');
    print('📱 Background Notification Body: ${message.notification!.body}');
  }

  // Process data payload if needed
  if (message.data.isNotEmpty) {
    print('📊 Background Message Data: ${message.data}');

    // You can show local notification for background messages
    if (message.notification != null) {
      await NotificationService().showSimpleNotification(
        title: message.notification!.title ?? 'Jaan Broast',
        body: message.notification!.body ?? 'New notification',
        payload: message.data.toString(),
      );
    }
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

    // Initialize notification service
    print('🔔 Initializing Notification Service...');
    await NotificationService().initialize();
    print('✅ Notification Service initialized');

    // Check and update FCM token if user is logged in
    print('🔔 Checking FCM token status...');
    await FCMTokenManager.checkAndUpdateToken();
    print('✅ FCM token check complete');

    print('🎉 All initialization complete!');
  } catch (e, stackTrace) {
    print('❌ Initialization error: $e');
    print('📋 Stack trace: $stackTrace');
    print('⚠️ Continuing app launch without Firebase features...');
  }

  runApp(const MyApp());
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
          return MaterialApp(
            title: 'Jaan Broast',
            navigatorKey: NotificationNavigator.navigatorKey,
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
