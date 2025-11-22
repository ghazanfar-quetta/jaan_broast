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

  // ---------------------------------------------------------
  // ADDED: Forgot Password Handler
  // ---------------------------------------------------------
  void _handleForgotPassword(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackbar(context, "Please enter your email first");
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.sendPasswordResetEmail(email);

    if (success && mounted) {
      _showSuccessSnackbar(context, 'Password reset email sent!');
    } else {
      _showErrorSnackbar(context, authViewModel.errorMessage);
    }
  }

  // SIGN IN / SIGN UP FUNCTIONS (UNCHANGED)
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
    bool success = await authViewModel.signInWithGoogle();

    if (!success && authViewModel.errorMessage.contains('subtype')) {
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
      _showErrorSnackbar(
        context,
        'Please fill in all required fields correctly',
      );
    }
  }

  // SNACKBARS (UNCHANGED)
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

  void _showSuccessSnackbar(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: ScreenUtils.responsivePadding(
              context,
              mobile: 20,
              tablet: 28,
              desktop: 32,
            ),
            child: Column(
              children: [
                // Top content - logo and header (fixed height)
                _buildTopSection(context),

                // Form section
                _buildForm(context),

                // Bottom section - sign up link
                _buildBottomSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildLogo(context),
      SizedBox(height: ScreenUtils.heightPercent(context, 0.02)),
      _buildHeader(context),
    ],
  );
  // -------------------------- UI COMPONENTS (UNCHANGED EXCEPT NEW LINK) --------------------------

  Widget _buildLogo(BuildContext context) => Container(
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
        errorBuilder: (_, __, ___) =>
            Icon(Icons.restaurant, size: 60, color: Colors.amber[700]),
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) => Column(
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
      SizedBox(height: 8),
      Text(
        'Please enter your account details here',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: 16,
            tablet: 17,
            desktop: 18,
          ),
        ),
      ),
      SizedBox(height: 20),
    ],
  );

  Widget _buildForm(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(
                height: ScreenUtils.heightPercent(context, 0.015),
              ), // Reduced
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

              // Forgot Password Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      _showErrorSnackbar(context, 'Please enter your email');
                      return;
                    }

                    final authViewModel = Provider.of<AuthViewModel>(
                      context,
                      listen: false,
                    );
                    final success = await authViewModel.sendPasswordResetEmail(
                      email,
                    );

                    if (success) {
                      _showSuccessSnackbar(
                        context,
                        'A password reset link has been sent on you registered Email Address. Please check your inbox and spam folder.',
                      );
                    } else {
                      // Check for common Firebase errors
                      final error = authViewModel.errorMessage.toLowerCase();
                      if (error.contains('user-not-found') ||
                          error.contains('no user')) {
                        _showErrorSnackbar(
                          context,
                          'No account found with this email address.',
                        );
                      } else if (error.contains('invalid-email')) {
                        _showErrorSnackbar(
                          context,
                          'Please enter a valid email address.',
                        );
                      } else if (error.contains('google') ||
                          error.contains('provider')) {
                        _showErrorSnackbar(
                          context,
                          'This email is registered with Google. Please sign in with Google instead of resetting password.',
                        );
                      } else {
                        _showErrorSnackbar(
                          context,
                          'Failed to send reset email. Please try again.',
                        );
                      }
                    }
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontSize: ScreenUtils.responsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: ScreenUtils.heightPercent(context, 0.015),
              ), // Reduced
              // Sign In Button + Guest + Google
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            mobile: 14, // Reduced
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

                  SizedBox(
                    height: ScreenUtils.heightPercent(context, 0.008),
                  ), // Reduced
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
                            mobile: 14, // Reduced
                            tablet: 15,
                            desktop: 16,
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

                  SizedBox(
                    height: ScreenUtils.heightPercent(context, 0.008),
                  ), // Reduced
                  // Sign in with Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: authViewModel.isLoading
                          ? null
                          : () => _handleGoogleSignIn(context),
                      icon: Image.asset(
                        'assets/images/google_logo.png',
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
                      label: Text(
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
                            mobile: 14, // Reduced
                            tablet: 15,
                            desktop: 16,
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
        Text(label, style: TextStyle(color: Colors.grey[700])),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: GestureDetector(
      onTap: () {
        AppRoutes.pushMaterialPage(
          context,
          const SignUpFormScreen(),
          routeName: AppRoutes.signUpForm,
        );
      },
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: const TextStyle(color: Colors.grey),
          children: [
            TextSpan(
              text: "Sign Up",
              style: TextStyle(
                color: Colors.amber[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
