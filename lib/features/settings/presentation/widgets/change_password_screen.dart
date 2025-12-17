import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/constants/button_styles.dart';
// Add these imports for logout functionality
import 'package:jaan_broast/core/services/auth_status_service.dart';
import 'package:jaan_broast/core/services/local_storage_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Change Password', showBackButton: true),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: ScreenUtils.responsivePadding(
        context,
        mobile: AppConstants.paddingLarge,
        tablet: AppConstants.paddingLarge,
        desktop: AppConstants.paddingLarge,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: AppConstants.paddingLarge),

            // Current Password Field
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              hintText: 'Enter your current password',
              obscureText: _obscureCurrentPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // New Password Field
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              hintText: 'Enter your new password',
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Confirm Password Field
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hintText: 'Confirm your new password',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Password Requirements
            _buildPasswordRequirements(),
            const SizedBox(height: AppConstants.paddingLarge),

            // Change Password Button
            _buildChangePasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change Your Password',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeMedium,
              tablet: AppConstants.headingSizeMedium,
              desktop: AppConstants.headingSizeLarge,
            ),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          'Enter your current password and set a new one to secure your account.',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          'Note: You will be logged out after password change and need to login again with new password.',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.captionTextSize,
              tablet: AppConstants.captionTextSize,
              desktop: AppConstants.captionTextSize,
            ),
            color: Theme.of(context).colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label.contains('New Password') && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Theme.of(context).primaryColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize,
              ),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildRequirementItem('At least 6 characters long'),
          _buildRequirementItem('Should not be the same as current password'),
          _buildRequirementItem('Confirm password must match new password'),
          _buildRequirementItem(
            'You will be logged out after successful change',
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize,
                  tablet: AppConstants.bodyTextSize,
                  desktop: AppConstants.bodyTextSize,
                ),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _changePassword,
        style: ButtonStyles.primaryButton(context).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return Theme.of(context).primaryColor.withOpacity(0.5);
            }
            return Theme.of(context).primaryColor;
          }),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Change Password',
                style: TextStyle(
                  fontSize: ScreenUtils.responsiveFontSize(
                    context,
                    mobile: AppConstants.bodyTextSize,
                    tablet: AppConstants.bodyTextSize,
                    desktop: AppConstants.bodyTextSize,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'New password and confirm password do not match.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validate password is not same as current
    if (_currentPasswordController.text == _newPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'New password must be different from current password.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      if (user.email == null) {
        throw Exception('User email not available');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      // Success - Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password changed successfully! Logging you out...',
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );

      // Log out user and navigate to login
      await _logoutAndNavigateToLogin(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password. ';

      switch (e.code) {
        case 'wrong-password':
          errorMessage += 'Current password is incorrect.';
          break;
        case 'weak-password':
          errorMessage += 'New password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage += 'Please log in again to change your password.';
          break;
        default:
          errorMessage += e.message ?? 'Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing password: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logoutAndNavigateToLogin(BuildContext context) async {
    try {
      final user = _auth.currentUser;

      // Update Firestore status
      if (user != null) {
        try {
          await AuthStatusService.setUserLoggedOut(user.uid);
        } catch (e) {
          print('⚠️ Firestore update failed: $e');
        }
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Clear local storage
      await LocalStorageService.setIsLoggedIn(false);

      print('✅ User logged out after password change');

      // Navigate to login screen
      _navigateToLoginScreen(context);
    } catch (e) {
      print('❌ Error during logout: $e');
      // Still try to navigate
      _navigateToLoginScreen(context);
    }
  }

  void _navigateToLoginScreen(BuildContext context) {
    // Close any open dialogs or loading indicators
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);

    // Show final message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login with your new password'),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
