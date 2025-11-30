import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Settings', showBackButton: false),
      body: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // User Profile Header
        _buildUserProfileHeader(context),

        // Settings Options List
        Expanded(child: _buildSettingsList(context)),

        // App Version Footer
        _buildAppVersionFooter(context),
      ],
    );
  }

  Widget _buildUserProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(
        ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingMedium,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge,
        ),
      ),
      padding: EdgeInsets.all(
        ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingMedium,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: ScreenUtils.responsiveValue(
              context,
              mobile: 80,
              tablet: 100,
              desktop: 120,
            ),
            height: ScreenUtils.responsiveValue(
              context,
              mobile: 80,
              tablet: 100,
              desktop: 120,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              size: ScreenUtils.responsiveValue(
                context,
                mobile: 40,
                tablet: 50,
                desktop: 60,
              ),
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // User Name
          Text(
            'Ghazanfar Ali',
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

          // Edit Profile Button
          TextButton(
            onPressed: () {
              // Navigate to edit profile screen
              print('Edit profile tapped');
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: ScreenUtils.responsiveFontSize(
                  context,
                  mobile: AppConstants.captionTextSize,
                  tablet: AppConstants.bodyTextSize,
                  desktop: AppConstants.bodyTextSize,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingMedium,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge,
        ),
      ),
      children: [
        _buildListTile(
          context: context,
          icon: Icons.person_outline,
          title: 'My Account',
          onTap: () => _handleAccountTap(),
        ),
        _buildListTile(
          context: context,
          icon: Icons.restaurant_outlined,
          title: 'Restaurant Details',
          onTap: () => _handleRestaurantDetailsTap(),
        ),
        _buildListTile(
          context: context,
          icon: Icons.payment_outlined,
          title: 'Payment History',
          onTap: () => _handlePaymentHistoryTap(),
        ),
        _buildDarkModeTile(context),
        _buildListTile(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _handlePrivacyPolicyTap(),
        ),
        _buildListTile(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => _handleHelpSupportTap(),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        _buildLogoutTile(context),
      ],
    );
  }

  Widget _buildDarkModeTile(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        return ListTile(
          leading: Icon(
            settingsViewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 22,
              tablet: 24,
              desktop: 26,
            ),
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize,
                tablet: AppConstants.bodyTextSize,
                desktop: AppConstants.bodyTextSize,
              ),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Switch(
            value: settingsViewModel.isDarkMode,
            onChanged: (value) {
              settingsViewModel.toggleDarkMode(value);
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          onTap: () {
            settingsViewModel.toggleDarkMode(!settingsViewModel.isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.logout,
        color: Theme.of(context).colorScheme.error,
        size: ScreenUtils.responsiveValue(
          context,
          mobile: 22,
          tablet: 24,
          desktop: 26,
        ),
      ),
      title: Text(
        'Log out',
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.bodyTextSize,
            tablet: AppConstants.bodyTextSize,
            desktop: AppConstants.bodyTextSize,
          ),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onTap: () => _showLogoutConfirmation(context),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
        size: ScreenUtils.responsiveValue(
          context,
          mobile: 22,
          tablet: 24,
          desktop: 26,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.bodyTextSize,
            tablet: AppConstants.bodyTextSize,
            desktop: AppConstants.bodyTextSize,
          ),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAppVersionFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingMedium,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge,
        ),
      ),
      child: Text(
        'App Version: 1.4.0[31]',
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.captionTextSize,
            tablet: AppConstants.bodyTextSize,
            desktop: AppConstants.bodyTextSize,
          ),
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  // Handler methods for different settings options
  void _handleAccountTap() {
    print('My Account tapped');
    // Navigate to account screen
  }

  void _handleRestaurantDetailsTap() {
    print('Restaurant Details tapped');
    // Navigate to restaurant details screen
  }

  void _handlePaymentHistoryTap() {
    print('Payment History tapped');
    // Navigate to payment history screen
  }

  void _handlePrivacyPolicyTap() {
    print('Privacy Policy tapped');
    // Navigate to privacy policy screen
  }

  void _handleHelpSupportTap() {
    print('Help & Support tapped');
    // Navigate to help & support screen
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Log Out',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.headingSizeMedium,
                tablet: AppConstants.headingSizeMedium,
                desktop: AppConstants.headingSizeMedium,
              ),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await _performLogout(context); // NOW THIS SHOULD WORK
              },
              child: Text(
                'Log Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final settingsViewModel = Provider.of<SettingsViewModel>(
      context,
      listen: false,
    );
    await settingsViewModel.logout(context); // ADD AWAIT AND MAKE METHOD ASYNC
    // The success message and navigation are now handled in the ViewModel
  }
}
