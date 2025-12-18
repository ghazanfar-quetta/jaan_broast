// lib/features/settings/presentation/views/settings_screen.dart
import 'dart:math';
import 'dart:convert';
import 'dart:async';
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
import 'package:jaan_broast/features/auth/presentation/view_models/auth_view_model.dart';

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
  String? _phoneNumber;
  bool _isLoading = true;

  // Add a StreamSubscription to listen for real-time updates
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _setupUserDataListener(); // Use listener instead of one-time load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = Provider.of<SettingsViewModel>(
        context,
        listen: false,
      );
      // settingsViewModel.initializeNotificationSettings();
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when screen is disposed
    _userDataSubscription?.cancel();
    super.dispose();
  }

  // In SettingsScreen.dart, in the _setupUserDataListener method:
  void _setupUserDataListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _userDataSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              _updateUserDataFromSnapshot(snapshot);

              // 🔄 RELOAD notification preference when user data changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final settingsViewModel = Provider.of<SettingsViewModel>(
                  context,
                  listen: false,
                );
                settingsViewModel.reloadNotificationPreference();
              });
            }
          });
    }
  }

  void _updateUserDataFromSnapshot(DocumentSnapshot snapshot) {
    final userData = snapshot.data() as Map<String, dynamic>?;
    final personalInfo = userData?['personalInfo'] as Map<String, dynamic>?;

    // Get user from auth for fallback
    final authUser = _auth.currentUser;

    setState(() {
      // Get name from Firestore or Auth
      _userName =
          personalInfo?['fullName'] as String? ??
          userData?['displayName'] as String? ??
          authUser?.displayName ??
          'User';

      // Get phone from Firestore
      _phoneNumber = personalInfo?['phoneNumber'] as String?;

      // Get profile image - try multiple sources
      _profileImageUrl = userData?['photoUrl'] as String? ?? authUser?.photoURL;

      _isLoading = false;
    });

    print('✅ Updated user data from Firestore:');
    print('   Name: $_userName');
    print('   Phone: $_phoneNumber');
    print('   Image URL: $_profileImageUrl');
  }

  void _updateUserDataFromAuth(User? user) {
    setState(() {
      _userName = user?.displayName ?? 'User';
      _phoneNumber = user?.phoneNumber;
      _profileImageUrl = user?.photoURL;
      _isLoading = false;
    });

    print('ℹ️ Using auth data: $_userName');
  }

  // Force refresh method
  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Force fetch from Firestore
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          _updateUserDataFromSnapshot(snapshot);
        } else {
          _updateUserDataFromAuth(user);
        }
      } else {
        setState(() {
          _userName = 'Guest User';
          _profileImageUrl = null;
          _phoneNumber = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleHelpSupportTap() {
    print('Help & Support tapped');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
  }

  void _handleAccountTap() {
    print('My Account tapped');

    // Navigate and then refresh when returning
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ProfileEditScreen(
              onProfileUpdated: (newImageUrl) {
                // Immediately update image
                if (newImageUrl != null) {
                  setState(() {
                    _profileImageUrl = newImageUrl;
                  });
                }
                // Also trigger a refresh
                _refreshUserData();
              },
            ),
          ),
        )
        .then((value) {
          // Always refresh when returning
          _refreshUserData();
        });
  }

  // Update the _loadLocalProfilePicture method if you still want to use it
  Future<String?> _loadLocalProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBase64Image = prefs.getString('profile_picture_base64');

      if (savedBase64Image != null && savedBase64Image.isNotEmpty) {
        return savedBase64Image;
      }
      return null;
    } catch (e) {
      print('❌ Error loading Base64 profile picture: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: false,
        automaticallyImplyLeading: false,
      ),
      body: _SettingsContent(
        userName: _userName,
        profileImageUrl: _profileImageUrl,
        phoneNumber: _phoneNumber,
        isLoading: _isLoading,
        onAccountTap: _handleAccountTap,
        onHelpSupportTap: _handleHelpSupportTap,
        parentContext: context,
      ),
    );
  }
}

// ... rest of your _SettingsContent class remains the same ...

class _SettingsContent extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final String? phoneNumber;
  final bool isLoading;
  final VoidCallback onAccountTap;
  final VoidCallback onHelpSupportTap;
  final BuildContext parentContext;

  const _SettingsContent({
    Key? key,
    required this.userName,
    required this.profileImageUrl,
    this.phoneNumber,
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
                                    mobile: 16.0, // Larger font
                                    tablet: 30.0,
                                    desktop: 40.0,
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
                          phoneNumber?.isNotEmpty == true
                              ? phoneNumber!
                              : 'Account Settings',
                          style: TextStyle(
                            fontSize: ScreenUtils.responsiveFontSize(
                              context,
                              mobile: 12.0,
                              tablet: 20.0,
                              desktop: 25.0,
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
        // Show loading if view model is still loading
        if (settingsViewModel.isLoading) {
          return ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        }

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

  // In your SettingsScreen.dart, replace the entire _showLogoutConfirmation and _performLogout methods:

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
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Simple direct logout without any complex logic
    try {
      await FirebaseAuth.instance.signOut();
      print('✅ Simple logout successful');
    } catch (e) {
      print('⚠️ Simple logout error (ignoring): $e');
    }

    // ALWAYS close loading and navigate
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading

      // Simple navigation - adjust route name as needed
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/auth', // Try '/login' if this doesn't work
        (route) => false,
      );
    }
  }

  void _navigateToLoginScreen(BuildContext context) {
    print('🚀 Navigating to login screen...');

    // Try multiple navigation methods to ensure success
    try {
      // Method 1: Try pushNamedAndRemoveUntil with '/auth'
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      print('📱 Navigation successful with /auth route');
    } catch (e) {
      print('⚠️ Route /auth failed: $e');

      try {
        // Method 2: Try pushNamedAndRemoveUntil with '/login'
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        print('📱 Navigation successful with /login route');
      } catch (e2) {
        print('⚠️ Route /login failed: $e2');

        try {
          // Method 3: Try direct MaterialPageRoute to your AuthScreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) {
                // IMPORTANT: Replace this with your actual AuthScreen import
                // return AuthScreen();

                // For now, let's try to find the correct route
                // First, try to navigate using the navigator key if you have one
                return Scaffold(
                  appBar: AppBar(title: const Text('Login')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Logged out successfully'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Try to go to auth again
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/auth',
                              (route) => false,
                            );
                          },
                          child: const Text('Go to Login'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            (route) => false,
          );
          print('📱 Navigation successful with MaterialPageRoute');
        } catch (e3) {
          print('❌ All navigation methods failed: $e3');

          // Last resort: Pop everything
          Navigator.popUntil(context, (route) => false);

          // Show error but at least we're not stuck
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out. Please restart the app.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
