// lib/core/services/notification_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // ADD THIS for Color
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz; // ADD THIS for timezone
import 'package:timezone/data/latest.dart' as tz; // ADD THIS
import 'package:firebase_messaging/firebase_messaging.dart';

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
          requestAlertPermission: true,
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
      'jaan_broast_channel', // Same as in AndroidManifest.xml
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
    // Request permission (already done in main.dart, but good to have here too)
    await _requestPermission();

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

    // Handle notification tap
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
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional:
            true, // Allows sending notifications without explicit user permission
      );
      print('🔔 iOS Notification permission: ${settings.authorizationStatus}');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    // Build notification details
    AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'jaan_broast_channel',
      'Jaan Broast Notifications',
      channelDescription: 'Order updates and offers',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      // Remove or fix sound reference if you don't have custom sound
      // sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([
        0,
        500,
        1000,
        500,
      ]), // FIXED: Now defined
      showWhen: true,
      autoCancel: true,
      colorized: true,
      color: const Color(
        0xFFE65100,
      ), // Orange color matching your theme - FIXED
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
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

  // Handle notification payload/data
  void _handleNotificationPayload(String payload) {
    try {
      // Parse payload (assuming it's JSON string)
      // You can customize this based on your notification structure
      print('🔔 Notification payload: $payload');

      // Example: Navigate based on notification type
      // if (type == 'order_update') { ... }
    } catch (e) {
      print('🔔 Error parsing notification payload: $e');
    }
  }

  // Handle message navigation
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? 'general';

    print('🔔 Navigating for notification type: $type');

    // You'll need to implement navigation logic here
    // This requires access to Navigator context
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('🔔 FCM Token retrieved: $token');
      return token;
    } catch (e) {
      print('🔔 Error getting FCM token: $e');
      return null;
    }
  }

  // Schedule a local notification (for reminders, etc.)
  Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Convert DateTime to TZDateTime
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local, // FIXED: Now defined
    );

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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      title,
      body,
      scheduledTZDate, // FIXED
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
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
