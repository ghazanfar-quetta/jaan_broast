// lib/features/location/presentation/views/location_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/screen_utils.dart';
import '../view_models/location_view_model.dart';
import 'package:jaan_broast/features/auth/presentation/view_models/auth_view_model.dart';

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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMapForAddress,
                ),
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
    // NEW: Show dialog for changing address method
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Address'),
        content: const Text('How would you like to update your address?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getCurrentLocationForAddress();
            },
            child: const Text('Use Current Location'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openManualAddressSearch();
            },
            child: const Text('Search Manually'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // NEW: Get current location for address
  void _getCurrentLocationForAddress() async {
    final locationViewModel = Provider.of<LocationViewModel>(
      context,
      listen: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Getting your current location...'),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 30), // Long duration for loading
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

  // NEW: Open manual address search (placeholder for Google Maps integration)
  void _openManualAddressSearch() {
    // TODO: Implement Google Maps Places API for address search
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Manual address search will be implemented with Google Maps Places API',
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 3),
      ),
    );

    // For now, just focus on the address field
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_addressController as FocusNode?);
    });
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final locationViewModel = Provider.of<LocationViewModel>(
        context,
        listen: false,
      );

      // Update location with the entered address
      locationViewModel.updateLocationManually(
        _addressController.text,
        lat: locationViewModel.latitude,
        lng: locationViewModel.longitude,
      );

      // Mark first login as completed
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.completeFirstLogin();

      // TODO: Save personal info to user profile

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address saved successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
}
