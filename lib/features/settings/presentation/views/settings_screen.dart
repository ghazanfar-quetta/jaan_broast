// live/features/settings/presentation/views/settings_screen.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/profile_edit_screen.dart';
import '../widgets/privacy_policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/help_support_screen.dart';
import '../widgets/restaurant_details_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = 'Loading...';
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = Provider.of<SettingsViewModel>(
        context,
        listen: false,
      );
      settingsViewModel.initializeNotificationSettings();
    });
  }

  void _handleHelpSupportTap() {
    print('Help & Support tapped');
    // Navigate to help & support screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();

          // Try to load locally saved profile picture first
          String? localImagePath = await _loadLocalProfilePicture();

          setState(() {
            _userName =
                userData?['displayName'] as String? ??
                user.displayName ??
                'User';

            // Use local picture if available, otherwise use Firebase URL
            _profileImageUrl =
                localImagePath ??
                userData?['photoUrl'] as String? ??
                user.photoURL;

            _isLoading = false;
          });
        } else {
          // Try to load locally saved profile picture first
          String? localImagePath = await _loadLocalProfilePicture();

          setState(() {
            _userName = user.displayName ?? 'User';

            // Use local picture if available, otherwise use Firebase URL
            _profileImageUrl = localImagePath ?? user.photoURL;

            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _userName = 'Guest User';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userName = 'Error loading name';
        _isLoading = false;
      });
    }
  }

  Future<String?> _loadLocalProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBase64Image = prefs.getString('profile_picture_base64');

      if (savedBase64Image != null && savedBase64Image.isNotEmpty) {
        print('✅ Loaded Base64 profile picture in Settings');
        print('📊 Base64 string length: ${savedBase64Image.length}');
        print(
          '📊 First 50 chars: ${savedBase64Image.substring(0, min(50, savedBase64Image.length))}...',
        );
        return savedBase64Image;
      } else {
        print('❌ No Base64 image found in SharedPreferences');
      }
      return null;
    } catch (e) {
      print('❌ Error loading Base64 profile picture: $e');
      return null;
    }
  }

  void _handleAccountTap() {
    print('My Account tapped');
    // Navigate to profile editing screen with callback
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ProfileEditScreen(
              onProfileUpdated: (newImageUrl) {
                // Update the local state with new profile picture
                setState(() {
                  _profileImageUrl = newImageUrl;
                });
              },
            ),
          ),
        )
        .then((_) {
          // Reload user data when returning from profile edit
          _loadUserData();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Settings', showBackButton: false),
      body: _SettingsContent(
        userName: _userName,
        profileImageUrl: _profileImageUrl,
        isLoading: _isLoading,
        onAccountTap: _handleAccountTap,
        onHelpSupportTap: _handleHelpSupportTap,
        parentContext: context,
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isLoading;
  final VoidCallback onAccountTap;
  final VoidCallback onHelpSupportTap;
  final BuildContext parentContext;

  const _SettingsContent({
    Key? key,
    required this.userName,
    required this.profileImageUrl,
    required this.isLoading,
    required this.onAccountTap,
    required this.onHelpSupportTap,
    required this.parentContext,
  }) : super(key: key);

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
    final headerHeight = ScreenUtils.responsiveValue(
      context,
      mobile: 250.0, // Reduced height since we're not overlapping
      tablet: 270.0,
      desktop: 290.0,
    );

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(color: Theme.of(context).primaryColor, blurRadius: 1200),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Row layout for circle photo and username
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Profile Image on LEFT
                  Container(
                    width: 220, // Smaller circle for side-by-side layout
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(child: _buildProfileBackground(context)),
                  ),

                  const SizedBox(width: 20), // Spacing between circle and text
                  // Username on RIGHT (vertically centered)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoading
                            ? SizedBox(
                                height: 24,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                _getDisplayName(userName),
                                style: TextStyle(
                                  fontSize: ScreenUtils.responsiveFontSize(
                                    context,
                                    mobile: 22.0, // Larger font
                                    tablet: 24.0,
                                    desktop: 26.0,
                                  ),
                                  fontWeight: FontWeight.w700, // Bolder
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 4,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                        const SizedBox(height: 8),

                        // Optional: Add user email or status
                        Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: ScreenUtils.responsiveFontSize(
                              context,
                              mobile: 14.0,
                              tablet: 15.0,
                              desktop: 16.0,
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String name) {
    // Truncate name if it's too long
    if (name.length > 15) {
      return '${name.substring(0, 12)}...';
    }
    return name;
  }

  Widget _buildProfileBackground(BuildContext context) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return _buildProfileImage(context, profileImageUrl!);
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
              Theme.of(context).primaryColor.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      );
    }
  }

  Widget _buildProfileImage(BuildContext context, String imageUrl) {
    // DEBUG: Print what we're receiving
    print(
      '🔍 Building profile image with: ${imageUrl.substring(0, min(30, imageUrl.length))}...',
    );
    print('🔍 Image URL starts with /: ${imageUrl.startsWith('/')}');
    print('🔍 Image URL starts with http: ${imageUrl.startsWith('http')}');
    print('🔍 Image URL length: ${imageUrl.length}');

    // BETTER Base64 detection: Check if it's likely Base64
    bool isLikelyBase64(String str) {
      // Base64 strings are typically long and contain specific character sets
      if (str.length < 100)
        return false; // Too short for meaningful Base64 image

      // Check for common Base64 patterns
      // JPEG Base64 often starts with "/9j/" (which is confusing our detection!)
      if (str.startsWith('/9j/') ||
          str.startsWith('iVBORw') ||
          str.startsWith('R0lGOD')) {
        return true;
      }

      // Check if string contains only valid Base64 chars
      final validBase64Regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
      return validBase64Regex.hasMatch(str);
    }

    final isBase64 = isLikelyBase64(imageUrl);
    print('🔍 Is likely Base64: $isBase64');

    if (isBase64) {
      print('🔄 Attempting to decode Base64 image...');
      try {
        // Handle the "/9j/" prefix correctly - it's valid Base64 for JPEG
        final imageBytes = base64Decode(imageUrl);
        print('✅ Base64 decoded successfully, bytes: ${imageBytes.length}');

        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error displaying Base64 image: $error');
            return _buildDefaultBackground(context);
          },
        );
      } catch (e) {
        print('❌ Base64 decode error: $e');
        return _buildDefaultBackground(context);
      }
    }
    // Check if it's a network URL (starts with http/https)
    else if (imageUrl.startsWith('http')) {
      print('🔄 Loading network image...');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading network image: $error');
          return _buildDefaultBackground(context);
        },
      );
    }
    // Check if it's a local file path (starts with /)
    else if (imageUrl.startsWith('/')) {
      print('🔄 Loading local file image...');
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading local image: $error');
          return _buildDefaultBackground(context);
        },
      );
    }
    // Default background
    else {
      print('ℹ️ Using default background');
      return _buildDefaultBackground(context);
    }
  }

  Widget _buildDefaultBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
            Theme.of(context).primaryColor.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingMedium.toDouble(),
          tablet: AppConstants.paddingLarge.toDouble(),
          desktop: AppConstants.paddingLarge.toDouble(),
        ),
      ),
      children: [
        SizedBox(height: 10),
        _buildListTile(
          context: context,
          icon: Icons.person_outline,
          title: 'My Account',
          onTap: onAccountTap,
        ),
        _buildListTile(
          context: context,
          icon: Icons.restaurant_outlined,
          title: 'Restaurant Details',
          onTap: () => _handleRestaurantDetailsTap(parentContext),
        ),

        // DARK MODE TILE
        _buildDarkModeTile(context),
        _buildNotificationTile(context),
        _buildListTile(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: onHelpSupportTap,
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        _buildLogoutTile(context),
      ],
    );
  }

  // DARK MODE TILE METHOD
  Widget _buildDarkModeTile(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        return ListTile(
          leading: Icon(
            settingsViewModel.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).primaryColor,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
            ),
          ),
          title: Text(
            'Dark Mode',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize.toDouble(),
                tablet: AppConstants.bodyTextSize.toDouble(),
                desktop: AppConstants.bodyTextSize.toDouble(),
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

  // NOTIFICATION TILE METHOD - ADD THIS
  Widget _buildNotificationTile(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        return ListTile(
          leading: Icon(
            settingsViewModel.notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: Theme.of(context).primaryColor,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 22.0,
              tablet: 24.0,
              desktop: 26.0,
            ),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: ScreenUtils.responsiveFontSize(
                context,
                mobile: AppConstants.bodyTextSize.toDouble(),
                tablet: AppConstants.bodyTextSize.toDouble(),
                desktop: AppConstants.bodyTextSize.toDouble(),
              ),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: settingsViewModel.notificationsEnabled
              ? Text(
                  'Receive order updates and offers',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: AppConstants.captionTextSize.toDouble(),
                      tablet: AppConstants.captionTextSize.toDouble(),
                      desktop: AppConstants.captionTextSize.toDouble(),
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Switch(
            value: settingsViewModel.notificationsEnabled,
            onChanged: (value) {
              settingsViewModel.toggleNotifications(value);
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          onTap: () {
            settingsViewModel.toggleNotifications(
              !settingsViewModel.notificationsEnabled,
            );
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
          mobile: 22.0,
          tablet: 24.0,
          desktop: 26.0,
        ),
      ),
      title: Text(
        'Log out',
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.bodyTextSize.toDouble(),
            tablet: AppConstants.bodyTextSize.toDouble(),
            desktop: AppConstants.bodyTextSize.toDouble(),
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
          mobile: 22.0,
          tablet: 24.0,
          desktop: 26.0,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.bodyTextSize.toDouble(),
            tablet: AppConstants.bodyTextSize.toDouble(),
            desktop: AppConstants.bodyTextSize.toDouble(),
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
          mobile: AppConstants.paddingMedium.toDouble(),
          tablet: AppConstants.paddingLarge.toDouble(),
          desktop: AppConstants.paddingLarge.toDouble(),
        ),
      ),
      child: Text(
        'App Version: 1.4.1[0]',
        style: TextStyle(
          fontSize: ScreenUtils.responsiveFontSize(
            context,
            mobile: AppConstants.captionTextSize.toDouble(),
            tablet: AppConstants.bodyTextSize.toDouble(),
            desktop: AppConstants.bodyTextSize.toDouble(),
          ),
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  void _handleRestaurantDetailsTap(BuildContext context) {
    print('Restaurant Details tapped');
    // Navigate to restaurant details screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RestaurantDetailsScreen()),
    );
  }

  void _handlePaymentHistoryTap() {
    print('Payment History tapped');
    // Navigate to payment history screen
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
                mobile: AppConstants.headingSizeMedium.toDouble(),
                tablet: AppConstants.headingSizeMedium.toDouble(),
                desktop: AppConstants.headingSizeMedium.toDouble(),
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
                mobile: AppConstants.bodyTextSize.toDouble(),
                tablet: AppConstants.bodyTextSize.toDouble(),
                desktop: AppConstants.bodyTextSize.toDouble(),
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
                await _performLogout(context);
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
    await settingsViewModel.logout(context);
    // The success message and navigation are now handled in the ViewModel
  }
}
