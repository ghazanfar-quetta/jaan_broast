// lib/features/auth/presentation/view_models/auth_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/local_storage_service.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      print('🔄 AuthViewModel: Starting Google Sign-In...');

      final User? user = await _authService.signInWithGoogle();

      if (user != null) {
        print(
          '✅ AuthViewModel: Google Sign-In successful, setting logged in state',
        );
        await LocalStorageService.setIsLoggedIn(true);
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
        await LocalStorageService.setIsLoggedIn(true);
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
        await LocalStorageService.setIsLoggedIn(true);
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
    _setLoading(true);
    _errorMessage = '';

    try {
      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Please fill in all fields';
        _setLoading(false);
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
        _setLoading(false);
        return false;
      }

      final User? user = await _authService.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        await LocalStorageService.setIsLoggedIn(true);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Sign-up failed. Please try again.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during sign-up: $e';
      _setLoading(false);
      return false;
    }
  }

  // Continue as Guest (Anonymous)
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final User? user = await _authService.signInAnonymously();

      if (user != null) {
        await LocalStorageService.setIsLoggedIn(true);
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
