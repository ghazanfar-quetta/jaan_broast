// lib/features/auth/presentation/view_models/auth_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/user_service.dart';
import 'package:jaan_broast/core/services/fcm_service.dart';
import 'package:jaan_broast/core/services/auth_status_service.dart';
import 'package:jaan_broast/core/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool _isSigningOut = false;
  bool get isSigningOut => _isSigningOut;

  Future<void> _createUserDocumentAfterAuth(User user) async {
    try {
      await _userService.createOrUpdateUserDocument(user);
      print('✅ User document created/updated for: ${user.uid}');
    } catch (e) {
      print('❌ Error creating user document: $e');
      // Don't throw - auth succeeded even if document creation failed
    }
  }

  // FCM Token Management after successful authentication
  Future<void> _handlePostAuthSuccess(User user) async {
    try {
      // 1. Create/update user document
      await _createUserDocumentAfterAuth(user);

      // 2. Mark user as logged in
      await AuthStatusService.setUserLoggedIn(user.uid);

      // 3. Request notification permission AFTER login (only once)
      await _requestNotificationPermissionOnce(user);

      // 4. Refresh FCM token
      await FCMService.refreshFCMToken();

      // 5. Set logged in state
      await LocalStorageService.setIsLoggedIn(true);

      print('✅ Auth success - User logged in: ${user.uid}');
    } catch (e) {
      print('⚠️ Post-auth processing error (non-critical): $e');
    }
  }

  // Add this new method:
  Future<void> _requestNotificationPermissionOnce(User user) async {
    try {
      final hasAsked =
          await LocalStorageService.getHasSetNotificationPreference();

      if (!hasAsked) {
        print('🔔 First time login - requesting notification permission...');

        final granted = await PermissionService.requestNotificationPermission();

        // Save to LocalStorageService
        await LocalStorageService.setOnboardingNotificationPreference(granted);
        await LocalStorageService.setHasSetNotificationPreference(true);

        // ✅ ADD THESE 3 LINES - Save to SharedPreferences (SettingsViewModel reads this)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          'notificationsEnabled',
          granted,
        ); // MUST MATCH SettingsViewModel key

        // Update Firebase
        await _userService.updateNotificationPreference(user.uid, granted);

        if (granted) {
          print('✅ User allowed notifications');
        } else {
          print('⚠️ User declined notifications');
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      await LocalStorageService.setHasSetNotificationPreference(true);
    }
  }

  // Check if this is user's first login
  Future<bool> _isFirstLogin(User user) async {
    final hasLoggedInBefore = await LocalStorageService.getHasLoggedInBefore();
    return !hasLoggedInBefore;
  }

  // Mark user as having logged in before
  Future<void> _markAsLoggedInBefore() async {
    await LocalStorageService.setHasLoggedInBefore(true);
  }

  // Check if location needs to be initialized (first login)
  Future<bool> needsLocationInitialization(User user) async {
    return await _isFirstLogin(user);
  }

  // Mark first login as completed
  Future<void> completeFirstLogin() async {
    await _markAsLoggedInBefore();
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      print('🔄 AuthViewModel: Starting Google Sign-In...');

      final User? user = await _authService.signInWithGoogle();

      if (user != null) {
        print('✅ AuthViewModel: Google Sign-In successful');

        // Handle post-auth success (including FCM token)
        await _handlePostAuthSuccess(user);

        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Google sign-in was cancelled or failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during Google sign-in: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Alternative Google Sign-In method for compatibility issues
  Future<bool> signInWithGoogleAlternative() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      print('🔄 AuthViewModel: Starting alternative Google Sign-In...');

      final User? user = await _authService.signInWithGoogle();

      if (user != null) {
        // Handle post-auth success (including FCM token)
        await _handlePostAuthSuccess(user);

        _setLoading(false);
        return true;
      } else {
        _errorMessage =
            'Google sign-in failed. Please check Firebase Console settings.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google sign-in error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Email and Password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Please fill in all fields';
        _setLoading(false);
        return false;
      }

      final User? user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        // Handle post-auth success (including FCM token)
        await _handlePostAuthSuccess(user);

        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during sign-in: $e';
      _setLoading(false);
      return false;
    }
  }

  // Sign up with Email and Password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = _authService.auth.currentUser;
      if (user != null) {
        // Handle post-auth success (including FCM token)
        await _handlePostAuthSuccess(user);
      }
      _errorMessage = '';
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage =
            'This email is already registered. Please use a different email or sign in.';
      } else if (e.code == 'weak-password') {
        _errorMessage =
            'The password is too weak. Please choose a stronger password.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'The email address is not valid.';
      } else {
        _errorMessage = e.message ?? 'Sign-up failed. Please try again.';
      }
      return false;
    } catch (e) {
      _errorMessage = 'Sign-up failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Continue as Guest (Anonymous)
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final User? user = await _authService.signInAnonymously();

      if (user != null) {
        // Handle post-auth success (including FCM token)
        await _handlePostAuthSuccess(user);

        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Guest sign-in failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during guest sign-in: $e';
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  // In AuthViewModel.dart
  Future<void> signOut() async {
    if (_isSigningOut) return;

    _setSigningOut(true);

    try {
      print('🔄 Starting sign out...');

      // Get user info
      final user = _authService.currentUser;
      final userId = user?.uid;

      // Update Firestore status
      if (userId != null) {
        try {
          await AuthStatusService.setUserLoggedOut(userId);
        } catch (e) {
          print('⚠️ Firestore update failed: $e');
        }
      }

      // Firebase signout
      await _authService.signOut();

      // Clear local storage
      await LocalStorageService.setIsLoggedIn(false);

      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      // Still clear local storage
      await LocalStorageService.setIsLoggedIn(false);
      rethrow;
    } finally {
      _setSigningOut(false);
    }
  }

  void _setSigningOut(bool value) {
    if (_isSigningOut != value) {
      _isSigningOut = value;
      notifyListeners();
    }
  }

  void _cancelAllListeners() {
    // Cancel any active Firestore stream subscriptions
    // Look for these in your ViewModel and cancel them
    // Example:
    // if (_ordersStreamSubscription != null) {
    //   _ordersStreamSubscription!.cancel();
    //   _ordersStreamSubscription = null;
    // }

    // If you're using StreamBuilder with .snapshots() directly,
    // Firebase will handle cancellation automatically.
    // But if you're managing subscriptions manually in ViewModel, cancel them here.
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) {
      _errorMessage = 'Please provide an email address.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.auth.sendPasswordResetEmail(email: email.trim());

      _errorMessage = '';
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'The email address is not valid.';
      } else {
        _errorMessage = e.message ?? e.code;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
