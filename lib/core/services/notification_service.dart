// lib/core/services/notification_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jaan_broast/core/utils/notification_navigator.dart';
import 'package:jaan_broast/core/services/user_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    await _initializeLocalNotifications();
    await _setupFirebaseMessaging();
  }

  // Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // We'll request separately
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
          macOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTap(response);
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  // Create notification channel for Android (required for Android 8.0+)
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'jaan_broast_channel',
      'Jaan Broast Notifications',
      description: 'Order updates, offers, and notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Setup Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    // Setup token refresh listener
    _setupTokenRefreshListener();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Handle when app is in background but opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from background notification');
      _handleMessageNavigation(message);
    });

    // Handle notification tap for terminated app
    _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((
      NotificationAppLaunchDetails? details,
    ) {
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null) {
          _handleNotificationPayload(payload);
        }
      }
    });

    // Get initial message if app was launched from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print('🔔 App launched from terminated state via notification');
      _handleMessageNavigation(initialMessage);
    }
  }

  // Setup token refresh listener
  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 iOS Notification permission: ${settings.authorizationStatus}');

      // Return true if authorized or provisional
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    // For Android, permissions are granted by default in manifest
    return true;
  }

  // Get FCM token and save to Firestore
  Future<String?> getAndSaveFCMToken() async {
    try {
      // First request permission if needed
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('🔔 Notification permission not granted');
        return null;
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('🔔 FCM Token retrieved: $token');

      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      return token;
    } catch (e) {
      print('🔔 Error getting/saving FCM token: $e');
      return null;
    }
  }

  // Save FCM token to Firestore
  // Save FCM token to Firestore using UserService
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('💾 Saving FCM token to Firestore for user: ${user.uid}');

        // Use UserService to save token
        final userService = UserService();
        await userService.saveFCMToken(user.uid, token);

        print('✅ FCM token saved to Firestore successfully');
      } else {
        print('⚠️ No user logged in, cannot save FCM token to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  // Remove FCM token from Firestore using UserService
  Future<void> removeFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🗑️ Removing FCM token from Firestore for user: ${user.uid}');

        // Use UserService to remove token
        final userService = UserService();
        await userService.removeFCMToken(user.uid);

        print('✅ FCM token removed from Firestore');
      }
    } catch (e) {
      print('❌ Error removing FCM token from Firestore: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    // Build notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'jaan_broast_channel',
          'Jaan Broast Notifications',
          channelDescription: 'Order updates and offers',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
          showWhen: true,
          autoCancel: true,
          colorized: true,
          color: const Color(0xFFE65100),
        );

    DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification?.title ?? 'Jaan Broast',
      notification?.body ?? 'New notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    if (response.payload != null) {
      _handleNotificationPayload(response.payload!);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? 'general';
    final screen = data['screen'] ?? '';
    final orderId = data['orderId'] ?? '';

    print(
      '🔔 Navigating for notification type: $type, screen: $screen, orderId: $orderId',
    );

    // Handle navigation based on notification data
    if (screen == 'order_details' && orderId.isNotEmpty) {
      _navigateToOrderDetails(orderId);
    } else {
      // Default navigation to home
      _navigateToHome();
    }
  }

  // Navigate to order details screen
  void _navigateToOrderDetails(String orderId) {
    try {
      print('📍 Navigating to order details: $orderId');

      // You'll need to implement this based on your app's routing
      // For now, we'll use a simple approach
      // In the future, you can add a proper '/order-details' route

      // For now, navigate to home and pass the orderId
      NotificationNavigator.navigateToOrderDetails(orderId);
    } catch (e) {
      print('❌ Error navigating to order details: $e');
      _navigateToHome(); // Fallback to home
    }
  }

  // Navigate to home screen
  void _navigateToHome() {
    try {
      print('📍 Navigating to home screen');
      NotificationNavigator.navigateToHome();
    } catch (e) {
      print('❌ Error navigating to home: $e');
    }
  }

  // Handle notification payload/data - REPLACE THE EXISTING METHOD WITH THIS
  void _handleNotificationPayload(String payload) {
    try {
      print('🔔 Notification payload: $payload');

      // Try to parse as JSON first
      try {
        // Remove curly braces and split into key-value pairs
        final cleanPayload = payload.replaceAll('{', '').replaceAll('}', '');
        final pairs = cleanPayload.split(',');

        Map<String, String> data = {};
        for (var pair in pairs) {
          final keyValue = pair.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim();
            final value = keyValue[1].trim();
            data[key] = value;
          }
        }

        final screen = data['screen'] ?? '';
        final orderId = data['orderId'] ?? '';

        if (screen == 'order_details' && orderId.isNotEmpty) {
          _navigateToOrderDetails(orderId);
        } else {
          _navigateToHome();
        }
      } catch (e) {
        print('🔔 Simple parsing failed, using fallback: $e');
        // Fallback: check if payload contains orderId
        if (payload.contains('orderId')) {
          // Simple extraction
          final regex = RegExp(r'orderId[:\s]*([^,\s}]+)');
          final match = regex.firstMatch(payload);
          if (match != null && match.groupCount >= 1) {
            final orderId = match.group(1)!;
            _navigateToOrderDetails(orderId);
          } else {
            _navigateToHome();
          }
        } else {
          _navigateToHome();
        }
      }
    } catch (e) {
      print('🔔 Error parsing notification payload: $e');
      _navigateToHome(); // Fallback to home
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Show simple notification without Firebase
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'jaan_broast_channel',
          'Jaan Broast Notifications',
          channelDescription: 'Order updates and offers',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
