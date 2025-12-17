// lib/features/auth/presentation/views/sign_up_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../../../../core/utils/screen_utils.dart';
import '../../../../core/utils/location_navigation_helper.dart'; // Add this import
import '../view_models/auth_view_model.dart';

class SignUpFormScreen extends StatefulWidget {
  const SignUpFormScreen({super.key});

  @override
  State<SignUpFormScreen> createState() => _SignUpFormScreenState();
}

class _SignUpFormScreenState extends State<SignUpFormScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // In lib/features/auth/presentation/views/sign_up_form_screen.dart

  void _handleSignUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      final success = await authViewModel.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        // Save user data to Firebase immediately after signup
        await _saveUserDataToFirebase();

        // UPDATED: Handle location initialization and navigation
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await LocationNavigationHelper.handlePostLoginNavigation(
            context,
            user,
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showErrorSnackbar(context, authViewModel.errorMessage);
      }
    }
  }

  // Add this method to save user data to Firebase
  Future<void> _saveUserDataToFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in after signup');
        return;
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Prepare user data
      final userData = {
        'personalInfo': {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': '', // Phone will be added later in location setup
          'createdAt': DateTime.now().toIso8601String(),
        },
        'appData': {
          'isFirstLoginCompleted':
              false, // Will be set to true after location setup
          'locationSetupCompleted': false,
          'accountCreatedAt': DateTime.now().toIso8601String(),
        },
      };

      // Save to Firestore
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userData, SetOptions(merge: true));

      print('✅ Signup data saved to Firebase');
      print('👤 User ID: ${currentUser.uid}');
      print('📝 Name: ${_nameController.text.trim()}');
      print('📧 Email: ${_emailController.text.trim()}');
    } catch (e) {
      print('❌ Error saving signup data to Firebase: $e');
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    Future.microtask(() {
      if (mounted && ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ScreenUtils.responsivePadding(
            context,
            mobile: 20,
            tablet: 28,
            desktop: 32,
          ),
          child: Column(
            children: [
              // Header section
              _buildHeader(context),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),

              // Form section
              _buildSignUpForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 28,
              tablet: 30,
              desktop: 32,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: ScreenUtils.heightPercent(context, 0.01)),
        Text(
          'Fill in your details to create a new account',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 17,
              desktop: 18,
            ),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              _buildInputField(
                context: context,
                label: 'Full Name',
                hintText: 'Enter your full name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.015)),

              // Email Field
              _buildInputField(
                context: context,
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.015)),

              // Password Field
              _buildInputField(
                context: context,
                label: 'Password',
                hintText: 'Enter your password',
                isPassword: true,
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.015)),

              // Confirm Password Field
              _buildInputField(
                context: context,
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.03)),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () => _handleSignUp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ScreenUtils.responsiveValue(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: authViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: ScreenUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),

              // Already have an account
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.01)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required String hintText,
    bool isPassword = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 17,
              desktop: 18,
            ),
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: ScreenUtils.heightPercent(context, 0.01)),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: ScreenUtils.responsiveValue(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
