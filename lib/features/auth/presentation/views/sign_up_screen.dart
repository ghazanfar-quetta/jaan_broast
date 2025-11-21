// lib/features/auth/presentation/views/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/screen_utils.dart';
import '../view_models/auth_view_model.dart';
import '../views/sign_up_form_screen.dart';
import 'package:jaan_broast/routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        _showSuccessSnackbar(context, 'Signed in successfully!');
        AppRoutes.pushReplacement(context, AppRoutes.home);
      } else {
        _showErrorSnackbar(context, authViewModel.errorMessage);
      }
    }
  }

  void _handleGuestSignIn(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.signInAnonymously();

    if (success && mounted) {
      _showSuccessSnackbar(context, 'Signed in as guest successfully!');
      AppRoutes.pushReplacement(context, AppRoutes.home);
    } else {
      _showErrorSnackbar(context, authViewModel.errorMessage);
    }
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    // Try main method first
    bool success = await authViewModel.signInWithGoogle();

    // If main method fails, try alternative
    if (!success && authViewModel.errorMessage.contains('subtype')) {
      print('🔄 Trying alternative Google Sign-In method...');
      success = await authViewModel.signInWithGoogleAlternative();
    }

    if (success && mounted) {
      _showSuccessSnackbar(context, 'Signed in with Google successfully!');
      AppRoutes.pushReplacement(context, AppRoutes.home);
    } else {
      _showErrorSnackbar(context, authViewModel.errorMessage);
    }
  }

  void _handleSignUp(BuildContext context) async {
    // Validate the form first
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        _showSuccessSnackbar(context, 'Account created successfully!');
        AppRoutes.pushReplacement(context, AppRoutes.home);
      } else {
        _showErrorSnackbar(context, authViewModel.errorMessage);
      }
    } else {
      // If form is not valid, show error
      _showErrorSnackbar(
        context,
        'Please fill in all required fields correctly',
      );
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    // Use Future.microtask to ensure context is valid
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

  void _showSuccessSnackbar(BuildContext context, String message) {
    // Use Future.microtask to ensure context is valid
    Future.microtask(() {
      if (mounted && ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showSignUpConfirmation(BuildContext context) {
    // Check if form has data
    final hasData =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

    if (hasData) {
      // If form has data, show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Account'),
          content: Text(
            'Would you like to create a new account with ${_emailController.text}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleSignUp(context);
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      );
    } else {
      // If form is empty, just trigger sign up which will show validation errors
      _handleSignUp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ScreenUtils.responsivePadding(
            context,
            mobile: 20,
            tablet: 28,
            desktop: 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: ScreenUtils.safeAreaHeight(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),
                // App Logo
                _buildLogo(context),
                SizedBox(height: ScreenUtils.heightPercent(context, 0.03)),
                // Header Section
                _buildHeader(context),
                SizedBox(height: ScreenUtils.heightPercent(context, 0.04)),
                // Form Section
                _buildForm(context),
                // Bottom Section
                _buildBottomSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: ScreenUtils.responsiveValue(
        context,
        mobile: 180,
        tablet: 216,
        desktop: 240,
      ),
      height: ScreenUtils.responsiveValue(
        context,
        mobile: 180,
        tablet: 216,
        desktop: 240,
      ),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(
          ScreenUtils.responsiveValue(
            context,
            mobile: 20,
            tablet: 22,
            desktop: 25,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ScreenUtils.responsiveValue(
            context,
            mobile: 20,
            tablet: 22,
            desktop: 25,
          ),
        ),
        child: Image.asset(
          'assets/images/onboarding/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(
                  ScreenUtils.responsiveValue(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 25,
                  ),
                ),
              ),
              child: Icon(
                Icons.restaurant,
                size: ScreenUtils.responsiveValue(
                  context,
                  mobile: 60, // Increased from 40
                  tablet: 70, // Increased from 45
                  desktop: 80, // Increased from 50
                ),
                color: Colors.amber[700],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome Back!',
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
          'Please enter your account details here',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: 16,
              tablet: 17,
              desktop: 18,
            ),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Section
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
              SizedBox(height: ScreenUtils.heightPercent(context, 0.03)),
              // Password Section
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
              SizedBox(height: ScreenUtils.heightPercent(context, 0.04)),
              // Divider
              Container(height: 1, color: Colors.grey[300]),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.04)),
              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () => _handleSignIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ScreenUtils.responsiveValue(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
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
                          'Sign In',
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
              // Continue as Guest
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () => _handleGuestSignIn(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ScreenUtils.responsiveValue(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),
              // Or Continue With
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or Continue With',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ScreenUtils.responsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),
              // Google Sign In with Google Logo
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () => _handleGoogleSignIn(context),
                  icon: Image.asset(
                    'assets/images/google_logo.png', // You'll need to add this image
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.red[700],
                      );
                    },
                  ),
                  label: authViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      : Text(
                          'Sign In With Google',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: ScreenUtils.responsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ScreenUtils.responsiveValue(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
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

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: ScreenUtils.heightPercent(context, 0.04),
        bottom: ScreenUtils.heightPercent(context, 0.02),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            // Navigate to the new sign up screen
            AppRoutes.pushMaterialPage(
              context,
              const SignUpFormScreen(),
              routeName:
                  AppRoutes.signUpForm, // Add this route to your routes.dart
            );
          },
          child: RichText(
            text: TextSpan(
              text: 'Don\'t have an account? ',
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
                  text: 'Sign Up',
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
    );
  }
}
