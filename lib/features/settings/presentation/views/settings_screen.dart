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

  const _SettingsContent({
    Key? key,
    required this.userName,
    required this.profileImageUrl,
    required this.isLoading,
    required this.onAccountTap,
    required this.onHelpSupportTap,
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
      mobile: 220.0,
      tablet: 240.0,
      desktop: 260.0,
    );

    return Container(
      width: double.infinity,
      height: headerHeight,
      margin: EdgeInsets.all(
        ScreenUtils.responsiveValue(
          context,
          mobile: AppConstants.paddingSmall.toDouble(),
          tablet: AppConstants.paddingMedium.toDouble(),
          desktop: AppConstants.paddingLarge.toDouble(),
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // IMPORTANT: This allows overflow
        children: [
          // Background Image - Full container
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: _buildProfileBackground(context),
          ),

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

          // Circular Name Badge at Bottom Center (50% overlapped)
          Positioned(
            bottom: -90, // Keep your -140 value
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Circular Badge
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      0.95,
                    ), // Fixed: withOpacity instead of withValues
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // User Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
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
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
        const SizedBox(height: 60), // Space for the overlapping circle

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
          onTap: () => _handleRestaurantDetailsTap(),
        ),

        // DARK MODE TILE
        _buildDarkModeTile(context),

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

  void _handleRestaurantDetailsTap() {
    print('Restaurant Details tapped');
    // Navigate to restaurant details screen
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
