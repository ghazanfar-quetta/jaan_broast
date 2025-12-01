import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ADD THIS
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // FOR File CLASS

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/utils/screen_utils.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/constants/button_styles.dart';
import '../../../../../core/services/permission_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import 'change_password_screen.dart'; // ADD THIS IMPORT

class ProfileEditScreen extends StatefulWidget {
  final Function(String?)? onProfileUpdated;

  const ProfileEditScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // ADD THIS

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false; // ADD SEPARATE FLAG FOR IMAGE UPLOAD
  String? _profileImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
          setState(() {
            _userModel = UserModel.fromFirestore(user.uid, userDoc.data()!);
            _nameController.text = _userModel?.displayName ?? '';
            _emailController.text = _userModel?.email ?? user.email ?? '';
            _phoneController.text = _userModel?.phoneNumber ?? '';
            _profileImageUrl = _userModel?.photoUrl;
            _isLoading = false;
          });
        } else {
          // Create basic user model from Firebase Auth data
          setState(() {
            _userModel = UserModel(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName,
              phoneNumber: user.phoneNumber,
              photoUrl: user.photoURL,
              isAnonymous: user.isAnonymous,
              isEmailVerified: user.emailVerified,
            );
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _phoneController.text = user.phoneNumber ?? '';
            _profileImageUrl = user.photoURL;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show source selection first
      final source = await _showImageSourceSelectionDialog();
      if (source == null) return;

      // Show uploading state immediately
      setState(() {
        _isUploadingImage = true;
      });

      // Handle permissions based on source
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        // For camera, request camera permission
        final status = await Permission.camera.request();
        hasPermission = status.isGranted;
      } else {
        // For gallery, try multiple permission types
        try {
          // First try photos permission (Android 13+)
          final photosStatus = await Permission.photos.request();
          if (photosStatus.isGranted) {
            hasPermission = true;
          } else {
            // Fallback to storage permission
            final storageStatus = await Permission.storage.request();
            hasPermission = storageStatus.isGranted;
          }
        } catch (e) {
          // Final fallback
          final storageStatus = await Permission.storage.request();
          hasPermission = storageStatus.isGranted;
        }
      }

      if (!hasPermission) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission denied. Please enable ${source == ImageSource.camera ? 'camera' : 'storage'} permissions in app settings.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        // Use local file path
        setState(() {
          _profileImageUrl = image.path;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image selected!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      } else {
        // User canceled image selection
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceSelectionDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: AppConstants.bodyTextSize,
                      tablet: AppConstants.bodyTextSize,
                      desktop: AppConstants.bodyTextSize,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: AppConstants.bodyTextSize,
                      tablet: AppConstants.bodyTextSize,
                      desktop: AppConstants.bodyTextSize,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      print('🔄 Starting Firebase Storage upload...');
      print('📁 File path: ${imageFile.path}');
      print('📁 File exists: ${await imageFile.exists()}');
      print('👤 User UID: ${user.uid}');

      // Create a reference to the location you want to upload to in Firebase Storage
      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('📤 Storage reference: ${storageRef.fullPath}');

      // Upload the file to Firebase Storage with metadata
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      print('📤 Upload task created, waiting for completion...');

      // Listen to the upload task to see progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
          '📊 Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} '
          '(${((snapshot.bytesTransferred / snapshot.totalBytes) * 100).toStringAsFixed(1)}%)',
        );
      });

      // Wait for the upload to complete with timeout
      final TaskSnapshot snapshot = await uploadTask
          .timeout(const Duration(seconds: 30))
          .catchError((error) {
            print('❌ Upload timeout or error: $error');
            throw Exception('Upload timed out after 30 seconds');
          });

      print('✅ Upload completed successfully!');

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('🔗 Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error in _uploadImageToFirebase: $e');

      // More detailed error handling
      if (e is FirebaseException) {
        print('🔥 Firebase Error Code: ${e.code}');
        print('🔥 Firebase Error Message: ${e.message}');

        if (e.code == 'storage/unauthorized') {
          throw Exception(
            'Storage permission denied. Check Firebase Storage rules.',
          );
        } else if (e.code == 'storage/canceled') {
          throw Exception('Upload was canceled.');
        } else if (e.code == 'storage/unknown') {
          throw Exception('Unknown storage error occurred.');
        }
      }

      throw e;
    }
  }

  Future<void> _saveProfile() async {
    if (_userModel == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user profile in Firebase Auth
        if (_nameController.text.trim() != user.displayName) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        // Update user data in Firestore
        // Note: We're only saving text data to Firestore (free)
        final updatedUser = _userModel!.copyWith(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          // We don't save the local image path as it won't work across devices
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(updatedUser.toFirestore(), SetOptions(merge: true));

        // CALL THE CALLBACK TO UPDATE SETTINGS SCREEN
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!(_profileImageUrl);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handleChangePassword() {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are logged in as a guest. Changing password is not available for guest accounts.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user signed in with Google
    final providerData = user.providerData;
    final isGoogleUser = providerData.any(
      (userInfo) => userInfo.providerId == 'google.com',
    );

    if (isGoogleUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are logged in with Google account. Changing password is not available for Google accounts.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // User is signed in with email/password - navigate to change password screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  bool get _hasChanges {
    return _nameController.text.trim() != (_userModel?.displayName ?? '') ||
        _phoneController.text.trim() != (_userModel?.phoneNumber ?? '') ||
        _profileImageUrl != _userModel?.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: CustomAppBar(title: 'Edit Profile', showBackButton: true),
      body: _isLoading
          ? _buildLoadingState()
          : _userModel == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Loading your profile...',
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
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: ScreenUtils.responsivePadding(
          context,
          mobile: AppConstants.paddingLarge,
          tablet: AppConstants.paddingLarge,
          desktop: AppConstants.paddingLarge,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Unable to load profile',
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
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
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
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ButtonStyles.primaryButton(context),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: ScreenUtils.responsivePadding(
        context,
        mobile: AppConstants.paddingMedium,
        tablet: AppConstants.paddingLarge,
        desktop: AppConstants.paddingLarge,
      ),
      child: Column(
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Form Fields
          _buildFormFields(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Change Password Button
          _buildChangePasswordButton(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: ScreenUtils.responsiveValue(
                context,
                mobile: 120,
                tablet: 140,
                desktop: 160,
              ),
              height: ScreenUtils.responsiveValue(
                context,
                mobile: 120,
                tablet: 140,
                desktop: 160,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: _isUploadingImage
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : _profileImageUrl != null
                  ? ClipOval(child: _buildProfileImage())
                  : Icon(
                      Icons.person,
                      size: ScreenUtils.responsiveValue(
                        context,
                        mobile: 50,
                        tablet: 60,
                        desktop: 70,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            if (!_isUploadingImage)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: ScreenUtils.responsiveValue(
                    context,
                    mobile: 36,
                    tablet: 40,
                    desktop: 44,
                  ),
                  height: ScreenUtils.responsiveValue(
                    context,
                    mobile: 36,
                    tablet: 40,
                    desktop: 44,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.background,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      size: ScreenUtils.responsiveValue(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                      color: Colors.white,
                    ),
                    onPressed: _pickImage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          _isUploadingImage ? 'Uploading...' : 'Tap to change photo',
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
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_profileImageUrl == null) {
      return Container();
    }

    // Check if it's a network URL (starts with http) or local file path
    if (_profileImageUrl!.startsWith('http')) {
      return Image.network(
        _profileImageUrl!,
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
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading network image: $error');
          return Icon(
            Icons.person,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 50,
              tablet: 60,
              desktop: 70,
            ),
            color: Theme.of(context).primaryColor,
          );
        },
      );
    } else {
      // It's a local file path
      return Image.file(
        File(_profileImageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading local image: $error');
          return Icon(
            Icons.person,
            size: ScreenUtils.responsiveValue(
              context,
              mobile: 50,
              tablet: 60,
              desktop: 70,
            ),
            color: Theme.of(context).primaryColor,
          );
        },
      );
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          hintText: 'Enter your full name',
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          hintText: 'Enter your email address',
          enabled: false, // Email cannot be changed directly
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
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
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (value) {
        setState(() {}); // Trigger rebuild to update save button state
      },
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: TextButton(
        onPressed: _handleChangePassword,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
        ),
        child: Text(
          'Change Password',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize,
            ),
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
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
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Changes',
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
