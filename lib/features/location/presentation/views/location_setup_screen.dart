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
import 'package:jaan_broast/features/home/presentation/views/home_screen.dart';

class LocationSetupScreen extends StatefulWidget {
  final bool isAutoLocation;
  final bool preserveContactDetails;

  const LocationSetupScreen({
    Key? key,
    required this.isAutoLocation,
    this.preserveContactDetails = false,
  }) : super(key: key);

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

  // Store the view model reference without using context
  LocationViewModel? _cachedLocationViewModel;
  bool _isDisposed = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && widget.isAutoLocation) {
        _initializeLocation();
      }
    });
    _loadSavedData();
    _ensureUserDataExists();
  }

  void _initializeLocation() {
    if (widget.isAutoLocation && !_isDisposed) {
      final locationViewModel = Provider.of<LocationViewModel>(
        context,
        listen: false,
      );

      _cachedLocationViewModel = locationViewModel;

      if (locationViewModel.currentLocation != 'Quetta') {
        _addressController.text = locationViewModel.currentLocation;
      }

      locationViewModel.addListener(_onLocationViewModelChanged);
    }
  }

  void _onLocationViewModelChanged() {
    if (_isDisposed || !mounted || _cachedLocationViewModel == null) return;
    if (!widget.isAutoLocation) return;

    final vm = _cachedLocationViewModel!;
    if (vm.isAutoLocation &&
        vm.currentLocation.isNotEmpty &&
        vm.currentLocation != 'Quetta') {
      if (_addressController.text != vm.currentLocation) {
        if (mounted) {
          setState(() {
            _addressController.text = vm.currentLocation;
          });
        }
      }
    }
  }

  // In lib/features/location/presentation/views/location_setup_screen.dart

  void _loadSavedData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        // ALWAYS load personal info if it exists, regardless of preserveContactDetails
        final personalInfo = userData?['personalInfo'] as Map<String, dynamic>?;
        if (personalInfo != null) {
          if (mounted) {
            setState(() {
              // Load name if available
              if (personalInfo['fullName'] != null &&
                  personalInfo['fullName'].toString().isNotEmpty) {
                _nameController.text =
                    personalInfo['fullName']?.toString() ?? '';
              }

              // Load phone if available
              if (personalInfo['phoneNumber'] != null &&
                  personalInfo['phoneNumber'].toString().isNotEmpty) {
                _phoneController.text =
                    personalInfo['phoneNumber']?.toString() ?? '';
              }
            });
          }
        }

        // Load address data only if preserveContactDetails is true
        if (widget.preserveContactDetails) {
          final address = userData?['address'] as Map<String, dynamic>?;
          if (address != null) {
            // You can load address data here if needed
          }
        } else {
          // First time setup - clear only address fields, keep contact info
          if (mounted) {
            setState(() {
              _landmarkController.clear();
              _streetNumberController.clear();
              _unitNumberController.clear();
              _selectedAddressType = null;
              if (!widget.isAutoLocation) {
                _addressController.clear();
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading saved data: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    print('🧹 Disposing LocationSetupScreen');
    _cleanupLocationServices();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _streetNumberController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }

  Future<void> _cleanupLocationServices() async {
    try {
      if (_cachedLocationViewModel != null) {
        _cachedLocationViewModel!.removeListener(_onLocationViewModelChanged);
        _cachedLocationViewModel = null;
      }
      // Add a small delay to ensure cleanup
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('⚠️ Error cleaning up location services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isNavigating) return false;
        await _handleBackAction();
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Delivery Address'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isNavigating) return;
              _handleBackAction();
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
      ),
    );
  }

  Future<void> _handleBackAction() async {
    if (_isNavigating) return;
    _isNavigating = true;

    print('🔙 Handling back action');

    if (!mounted) {
      _isNavigating = false;
      return;
    }

    // Stop location services FIRST
    await _cleanupLocationServices();

    // Wait for cleanup to complete
    await Future.delayed(const Duration(milliseconds: 300));

    if (!widget.preserveContactDetails) {
      final shouldGoHome = await _showBackConfirmationDialog();
      if (!shouldGoHome) {
        _isNavigating = false;
        return;
      }
    }

    // Navigate to home
    await _navigateToHome();
    _isNavigating = false;
  }

  Future<bool> _showBackConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Skip Setup?'),
            content: const Text(
              'You need to complete your profile to place orders. '
              'You can complete it later from your profile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CONTINUE SETUP'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('GO TO HOME'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _navigateToHome() async {
    print('🚀 Navigating to home screen');

    if (!mounted) {
      print('⚠️ Widget not mounted');
      return;
    }

    try {
      // Use pushAndRemoveUntil to clear all routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );

      print('✅ Navigation successful');
    } catch (e) {
      print('❌ Navigation error: $e');

      // Try alternative method - pushReplacementNamed
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/home');
          print('✅ Alternative navigation successful');
        } catch (e2) {
          print('❌ Alternative navigation also failed: $e2');

          // Last resort - pop current screen
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
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
        if (_cachedLocationViewModel == null && widget.isAutoLocation) {
          _cachedLocationViewModel = locationViewModel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isDisposed && mounted && _cachedLocationViewModel != null) {
              _cachedLocationViewModel!.addListener(
                _onLocationViewModelChanged,
              );
            }
          });
        }

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

        // Address Type Section
        Column(
          children: [
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: _selectedAddressType,
                isExpanded: true,
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
                    child: Text(type, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (mounted) {
                    setState(() {
                      _selectedAddressType = newValue;
                      _unitNumberController.clear();
                    });
                  }
                },
              ),
            ),

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
                      if (mounted) {
                        setState(() {
                          _selectedAddressType = null;
                          _unitNumberController.clear();
                        });
                      }
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
                    widget.preserveContactDetails
                        ? 'Update Address'
                        : 'Save Address & Continue',
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
    if (!mounted) return;

    final locationViewModel =
        _cachedLocationViewModel ??
        Provider.of<LocationViewModel>(context, listen: false);

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
    } else if (mounted) {
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

      final locationViewModel =
          _cachedLocationViewModel ??
          Provider.of<LocationViewModel>(context, listen: false);

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
    if (!mounted || _formKey.currentState == null) return;

    if (_formKey.currentState!.validate()) {
      final locationViewModel =
          _cachedLocationViewModel ??
          Provider.of<LocationViewModel>(context, listen: false);
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

      // Mark first login as completed (only if it's first time setup)
      if (!widget.preserveContactDetails) {
        authViewModel.completeFirstLogin();
      }

      // Navigate to home using the same method as back button
      _navigateToHome();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.preserveContactDetails
                ? 'Address updated successfully!'
                : 'Profile setup completed successfully!',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // In the same LocationSetupScreen file

  void _saveUserDataToFirebase(Map<String, dynamic> userData) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('❌ No user logged in. Cannot save data to Firebase.');
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

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // First, check if user already has personal info
      final existingDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic> dataToSave;

      if (existingDoc.exists) {
        // Merge existing data with new data
        final existingData = existingDoc.data()!;

        // Always preserve existing personalInfo fields
        final existingPersonalInfo =
            existingData['personalInfo'] as Map<String, dynamic>? ?? {};

        dataToSave = {
          ...existingData, // Keep all existing data
          // Update address
          'address': userData['address'],

          // Merge personal info - keep existing fields, add/update new ones
          'personalInfo': {
            ...existingPersonalInfo,
            'fullName': _nameController.text.trim(), // Update name
            'phoneNumber': _phoneController.text.trim(), // Update phone
          },

          // Update app data
          'appData': {
            ...existingData['appData'] ?? {},
            'isFirstLoginCompleted': true,
            'locationSetupCompleted': true,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
        };
      } else {
        // First time setup - use complete user data
        dataToSave = userData;
      }

      // Save merged data to Firestore
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(dataToSave, SetOptions(merge: true));

      // Save address as separate document
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

      print('✅ User data saved/merged successfully to Firebase');
      print('👤 User ID: ${currentUser.uid}');
      print('📝 Name: ${_nameController.text.trim()}');
      print('📱 Phone: ${_phoneController.text.trim()}');
      print('📍 Address: ${userData['address']['fullAddress']}');
    } catch (e) {
      print('❌ Error saving user data to Firebase: $e');
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

  Future<void> _ensureUserDataExists() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // If user document doesn't exist, create it with basic info
      if (!userDoc.exists) {
        final basicUserData = {
          'personalInfo': {
            'email': currentUser.email ?? '',
            'createdAt': DateTime.now().toIso8601String(),
          },
          'appData': {
            'isFirstLoginCompleted': false,
            'locationSetupCompleted': false,
            'accountCreatedAt': DateTime.now().toIso8601String(),
          },
        };

        await firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(basicUserData);

        print('✅ Created basic user document in Firebase');
      }
    } catch (e) {
      print('❌ Error ensuring user data exists: $e');
    }
  }
}
