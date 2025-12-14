// lib/core/services/auth_status_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call when user logs in
  static Future<void> setUserLoggedIn(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isCurrentlyLoggedIn': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User marked as logged in: $userId');
    } catch (e) {
      print('❌ Error marking user as logged in: $e');
    }
  }

  // Call when user logs out
  static Future<void> setUserLoggedOut(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isCurrentlyLoggedIn': false,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User marked as logged out: $userId');
    } catch (e) {
      print('❌ Error marking user as logged out: $e');
    }
  }

  // Update last active time (when app comes to foreground)
  static Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating last active: $e');
    }
  }

  // Check if user is logged in (optional)
  static Future<bool> isUserLoggedIn(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isCurrentlyLoggedIn'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }
}
