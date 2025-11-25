// lib/features/location/presentation/views/location_setup_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/screen_utils.dart';
import '../view_models/location_view_model.dart';
import 'package:jaan_broast/features/auth/presentation/view_models/auth_view_model.dart';
import 'address_search_screen.dart';

class LocationSetupScreen extends StatefulWidget {
  final bool isAutoLocation;

  const LocationSetupScreen({Key? key, required this.isAutoLocation})
    : super(key: key);

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  final TextEditingController _unitNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // New fields for address type
  String? _selectedAddressType;
  final List<String> _addressTypes = ['Flat', 'House', 'Suite', 'Office'];
  final Map<String, String> _addressTypeHints = {
    'Flat': 'Flat Number',
    'House': 'House Number',
    'Suite': 'Suite Number',
    'Office': 'Office Number',
  };

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadSavedData();
  }

  void _initializeLocation() async {
    if (widget.isAutoLocation) {
      final locationViewModel = Provider.of<LocationViewModel>(
        context,
        listen: false,
      );

      // Auto-location should already be set from the previous step
      // Just pre-fill the address field
      if (locationViewModel.currentLocation != 'Quetta') {
        _addressController.text = locationViewModel.currentLocation;
      }
    }
  }

  void _loadSavedData() async {
    // TODO: Load saved address data from Firebase/Firestore
    // This will be implemented when we integrate with backend
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    // Example: await authViewModel.loadUserAddressData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Delivery Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ScreenUtils.responsivePadding(
            context,
            mobile: 20,
            tablet: 24,
            desktop: 28,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildAddressSection(),
                const SizedBox(height: 20),
                _buildAddressDetailsSection(),
                const SizedBox(height: 20),
                _buildPersonalInfoSection(),
                const SizedBox(height: 30),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where should we deliver?',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeLarge,
              tablet: AppConstants.headingSizeLarge,
              desktop: AppConstants.headingSizeLarge + 4,
            ),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your delivery address and contact details',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.bodyTextSize,
              tablet: AppConstants.bodyTextSize,
              desktop: AppConstants.bodyTextSize + 2,
            ),
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Consumer<LocationViewModel>(
      builder: (context, locationViewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: ScreenUtils.responsiveFontSize(
                      context,
                      mobile: AppConstants.headingSizeSmall,
                      tablet: AppConstants.headingSizeSmall,
                      desktop: AppConstants.headingSizeSmall,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit_location_alt,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: _openMapForAddress,
                  tooltip: 'Change Address',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter your complete address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your delivery address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmarkController,
              decoration: InputDecoration(
                hintText: 'Nearby landmark (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                prefixIcon: const Icon(Icons.place),
              ),
            ),
            if (locationViewModel.isLoading) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
            if (locationViewModel.error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationViewModel.error,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAddressDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Details',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeSmall,
              tablet: AppConstants.headingSizeSmall,
              desktop: AppConstants.headingSizeSmall,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),

        // Street Number (Optional)
        TextFormField(
          controller: _streetNumberController,
          decoration: InputDecoration(
            hintText: 'Street Number (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            prefixIcon: const Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 12),

        // Address Type Section - FIXED OVERFLOW
        Column(
          children: [
            // Always show the dropdown
            Container(
              width: double.infinity, // Ensure it takes full width
              child: DropdownButtonFormField<String>(
                value: _selectedAddressType,
                isExpanded:
                    true, // This is the key fix - makes dropdown take full width
                decoration: InputDecoration(
                  hintText: 'Type (Flat, House, Suite, Office)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.type_specimen),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: _addressTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAddressType = newValue;
                    _unitNumberController.clear();
                  });
                },
              ),
            ),

            // Show unit number field only when address type is selected
            if (_selectedAddressType != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitNumberController,
                decoration: InputDecoration(
                  hintText: _addressTypeHints[_selectedAddressType] ?? 'Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedAddressType = null;
                        _unitNumberController.clear();
                      });
                    },
                    tooltip: 'Clear type',
                  ),
                ),
                validator: (value) {
                  if (_selectedAddressType != null &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter ${_addressTypeHints[_selectedAddressType]?.toLowerCase() ?? 'number'}';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details',
          style: TextStyle(
            fontSize: ScreenUtils.responsiveFontSize(
              context,
              mobile: AppConstants.headingSizeSmall,
              tablet: AppConstants.headingSizeSmall,
              desktop: AppConstants.headingSizeSmall,
            ),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Your full name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Phone number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Consumer<LocationViewModel>(
      builder: (context, locationViewModel, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: locationViewModel.isLoading ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: locationViewModel.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Address & Continue',
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
      },
    );
  }

  void _openMapForAddress() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.background,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_location_alt,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Update Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'How would you like to update your delivery address?',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _getCurrentLocationForAddress();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openManualAddressSearch();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Search Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _getCurrentLocationForAddress() async {
    final locationViewModel = Provider.of<LocationViewModel>(
      context,
      listen: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Getting your current location...'),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 30),
      ),
    );

    final success = await locationViewModel.retryAutoLocation();

    if (success && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _addressController.text = locationViewModel.currentLocation;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location updated successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationViewModel.error.isNotEmpty
                ? locationViewModel.error
                : 'Failed to get current location. Please try manual entry.',
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openManualAddressSearch() async {
    final selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressSearchScreen()),
    );

    if (selectedAddress != null && mounted) {
      setState(() {
        _addressController.text =
            selectedAddress['description'] ??
            selectedAddress['display_name'] ??
            'Selected Address';
      });

      final locationViewModel = Provider.of<LocationViewModel>(
        context,
        listen: false,
      );

      if (selectedAddress['lat'] != null && selectedAddress['lon'] != null) {
        locationViewModel.updateLocationManually(
          _addressController.text,
          lat: selectedAddress['lat'],
          lng: selectedAddress['lon'],
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address selected successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final locationViewModel = Provider.of<LocationViewModel>(
        context,
        listen: false,
      );
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Prepare complete user data for saving
      final userData = {
        // Address Information
        'address': {
          'fullAddress': _addressController.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'streetNumber': _streetNumberController.text.trim(),
          'addressType': _selectedAddressType,
          'unitNumber': _unitNumberController.text.trim(),
          'coordinates': {
            'latitude': locationViewModel.latitude,
            'longitude': locationViewModel.longitude,
          },
          'isAutoLocation': locationViewModel.isAutoLocation,
        },

        // Personal Information
        'personalInfo': {
          'fullName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        },

        // App & System Data
        'appData': {
          'isFirstLoginCompleted': true,
          'locationSetupCompleted': true,
          'lastUpdated': DateTime.now().toIso8601String(),
          'accountCreatedAt': DateTime.now().toIso8601String(),
        },

        // Delivery Preferences (default values)
        'deliveryPreferences': {
          'saveAddressForFuture': true,
          'contactlessDelivery': false,
          'deliveryInstructions': '',
        },
      };

      // Update location with the entered address
      locationViewModel.updateLocationManually(
        _addressController.text.trim(),
        lat: locationViewModel.latitude,
        lng: locationViewModel.longitude,
      );

      // Save complete user data to Firebase
      _saveUserDataToFirebase(userData);

      // Mark first login as completed
      authViewModel.completeFirstLogin();

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile setup completed successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveUserDataToFirebase(Map<String, dynamic> userData) async {
    try {
      // Get current user directly from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('❌ No user logged in. Cannot save data to Firebase.');

        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save your data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Initialize Firebase Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Save user data to Firestore
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userData, SetOptions(merge: true));

      // Also save address as a separate document for easy querying
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('addresses')
          .doc('primary')
          .set({
            ...userData['address'],
            'isPrimary': true,
            'createdAt': DateTime.now().toIso8601String(),
          });

      print('✅ User data saved successfully to Firebase');

      // Print confirmation
      print('📝 User Data saved to Firebase:');
      print('👤 User ID: ${currentUser.uid}');
      print('📧 User Email: ${currentUser.email}');
      print('📍 Address: ${userData['address']['fullAddress']}');
      print('📞 Phone: ${userData['personalInfo']['phoneNumber']}');
      print('👨‍💼 Name: ${userData['personalInfo']['fullName']}');
    } catch (e) {
      print('❌ Error saving user data to Firebase: $e');

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _streetNumberController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }
}
