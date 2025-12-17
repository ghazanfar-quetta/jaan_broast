import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize FCM
  static Future<void> initialize() async {
    await _setupLocalNotifications();
    await _requestPermissions();
    await _getTokenAndSave();
    await _setupForegroundHandler();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Setup local notifications
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Request permissions
  static Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Get and save FCM token
  static Future<void> _getTokenAndSave() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      final user = FirebaseAuth.instance.currentUser;
      if (token != null && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
              'notificationsEnabled': true,
            });
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Setup foreground handlers
  static Future<void> _setupForegroundHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.data}');
      _handleNotificationNavigation(message.data);
    });
  }

  // Show local notification (SIMPLIFIED)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'order_notifications',
          'Order Updates',
          channelDescription: 'Order status updates',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Jaan Broast',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final orderId = data['orderId'] ?? '';

    if (type.startsWith('order_') && orderId.isNotEmpty) {
      print('Navigate to order: $orderId');
    }
  }

  // Refresh token
  static Future<void> refreshFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      final user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }
}

// Background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background notification: ${message.notification?.title}');
}
