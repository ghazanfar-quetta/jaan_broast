// lib/core/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/domain/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update user document in Firestore
  Future<void> createOrUpdateUserDocument(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'phoneNumber': user.phoneNumber,
        'photoUrl': user.photoURL,
        'isAnonymous': user.isAnonymous,
        'isEmailVerified': user.emailVerified,
        'notificationsEnabled': true,
        'fcmToken': null,
        'isCurrentlyLoggedIn': true, // Default to true when creating
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Update existing document
        final existingData = userDoc.data();

        if (existingData != null) {
          // Preserve existing preferences
          if (existingData['notificationsEnabled'] != null) {
            userData['notificationsEnabled'] =
                existingData['notificationsEnabled'];
          }

          // Preserve login status if already set
          if (existingData['isCurrentlyLoggedIn'] != null) {
            userData['isCurrentlyLoggedIn'] =
                existingData['isCurrentlyLoggedIn'];
          } else {
            // Set to true since user is logging in
            userData['isCurrentlyLoggedIn'] = true;
          }

          // Preserve FCM token if exists
          if (existingData['fcmToken'] != null) {
            userData['fcmToken'] = existingData['fcmToken'];
          }
        }

        await _firestore.collection('users').doc(user.uid).update({
          ...userData,
          'lastActiveAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document updated for: ${user.uid}');
      } else {
        // Create new document - user is logging in, so set to true
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('✅ User document created for: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error creating/updating user document: $e');
      rethrow;
    }
  }

  // Get user document
  Future<UserModel?> getUserDocument(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(userId, data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user document: $e');
      return null;
    }
  }

  // Update user notification preference
  Future<void> updateNotificationPreference(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Notification preference updated: $enabled');
    } catch (e) {
      print('❌ Error updating notification preference: $e');
      rethrow;
    }
  }

  // Save FCM token
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      rethrow;
    }
  }

  // Remove FCM token
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token removed for user: $userId');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
      rethrow;
    }
  }

  // Check if user document exists
  Future<bool> userDocumentExists(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('❌ Error checking user document: $e');
      return false;
    }
  }
}
