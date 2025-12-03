// lib/features/location/presentation/view_models/location_view_model.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/location_service.dart';

class LocationViewModel with ChangeNotifier {
  String _currentLocation = 'Quetta';
  bool _isLoading = false;
  String _error = '';
  double? _latitude;
  double? _longitude;
  bool _isAutoLocation = false;
  List<Map<String, dynamic>> _searchResults = [];

  static const String _prefLocationKey = 'saved_location_data';
  static const String _prefAddressKey = 'saved_address';
  static const String _prefLatKey = 'saved_latitude';
  static const String _prefLngKey = 'saved_longitude';
  static const String _prefIsAutoKey = 'saved_is_auto';

  LocationViewModel() {
    _loadSavedLocation();
  }

  String get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String get error => _error;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isAutoLocation => _isAutoLocation;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // Load saved location from SharedPreferences
  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedAddress = prefs.getString(_prefAddressKey);
      final savedLat = prefs.getDouble(_prefLatKey);
      final savedLng = prefs.getDouble(_prefLngKey);
      final savedIsAuto = prefs.getBool(_prefIsAutoKey) ?? false;

      if (savedAddress != null &&
          savedAddress.isNotEmpty &&
          savedAddress != 'Quetta') {
        _currentLocation = savedAddress;
        _latitude = savedLat;
        _longitude = savedLng;
        _isAutoLocation = savedIsAuto;

        print('📍 Loaded saved location: $_currentLocation');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading saved location: $e');
    }
  }

  // Save location to SharedPreferences
  Future<void> _saveLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_prefAddressKey, _currentLocation);

      if (_latitude != null) {
        await prefs.setDouble(_prefLatKey, _latitude!);
      }

      if (_longitude != null) {
        await prefs.setDouble(_prefLngKey, _longitude!);
      }

      await prefs.setBool(_prefIsAutoKey, _isAutoLocation);

      // Also save as a combined map for easy retrieval
      final locationData = {
        'address': _currentLocation,
        'latitude': _latitude,
        'longitude': _longitude,
        'isAutoLocation': _isAutoLocation,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_prefLocationKey, locationData.toString());

      print('💾 Saved location: $_currentLocation');
    } catch (e) {
      print('❌ Error saving location: $e');
    }
  }

  // Clear saved location
  Future<void> clearSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefAddressKey);
      await prefs.remove(_prefLatKey);
      await prefs.remove(_prefLngKey);
      await prefs.remove(_prefIsAutoKey);
      await prefs.remove(_prefLocationKey);

      _currentLocation = 'Quetta';
      _latitude = null;
      _longitude = null;
      _isAutoLocation = false;

      notifyListeners();
      print('🗑️ Cleared saved location');
    } catch (e) {
      print('❌ Error clearing location: $e');
    }
  }

  // Search addresses method
  Future<List<Map<String, dynamic>>> searchAddresses(String query) async {
    try {
      if (query.length < 3) {
        return [];
      }

      return await LocationService.searchAddressesGoogleMaps(query);
    } catch (e) {
      print('LocationViewModel: Error searching addresses - $e');
      return [];
    }
  }

  // Get current location with complete address - FIXED VERSION
  Future<bool> retryAutoLocation() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;

        // Get complete address from location service
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address.isNotEmpty &&
            address !=
                'Lat: ${position.latitude}, Lng: ${position.longitude}') {
          _currentLocation = address;
        } else {
          // Fallback: Use coordinates if address lookup fails
          _currentLocation =
              'Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }

        _isAutoLocation = true;
        _error = '';

        // CRITICAL: Save location immediately after fetching
        await _saveLocation();

        print('📍 Auto-location success: $_currentLocation');
        print('📍 Coordinates: $_latitude, $_longitude');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Could not get current location';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Improved version with better error handling
  Future<bool> getCurrentLocationOnce() async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // First check if we already have a saved location
      if (_latitude != null &&
          _longitude != null &&
          _currentLocation != 'Quetta') {
        print('📍 Using already available location: $_currentLocation');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Request permission and get position
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        _error = 'Location service unavailable';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Store coordinates immediately
      _latitude = position.latitude;
      _longitude = position.longitude;

      print('📍 Got coordinates: $_latitude, $_longitude');

      // Try to get address
      String address;
      try {
        address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address.isEmpty || address.contains('Lat:')) {
          // Address lookup failed
          address = 'Your Current Location';
        }
      } catch (e) {
        print('⚠️ Address lookup failed: $e');
        address = 'Your Current Location';
      }

      _currentLocation = address;
      _isAutoLocation = true;
      _error = '';

      // Save to persistent storage
      await _saveLocation();

      print('📍 Location set: $_currentLocation');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Location error: $e');
      _error = 'Failed to get location: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Select address from search results
  Future<void> selectAddress(Map<String, dynamic> result) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentLocation = result['display_name'] ?? 'Unknown Address';
      _latitude = result['lat'];
      _longitude = result['lon'];
      _isAutoLocation = false;
      _searchResults = [];
      _error = '';

      // Save the selected location
      await _saveLocation();

      print('📍 Selected address: $_currentLocation');
    } catch (e) {
      _error = 'Failed to select address: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Update location manually
  Future<void> updateLocationManually(
    String location, {
    double? lat,
    double? lng,
  }) async {
    _currentLocation = location;
    _latitude = lat;
    _longitude = lng;
    _isAutoLocation = false;
    _error = '';

    // Save the manually updated location
    await _saveLocation();

    notifyListeners();
  }

  bool get isLocationSet =>
      _currentLocation.isNotEmpty &&
      _currentLocation != 'Quetta' &&
      _latitude != null &&
      _longitude != null;

  Map<String, dynamic> get locationData {
    return {
      'address': _currentLocation,
      'latitude': _latitude,
      'longitude': _longitude,
      'isAutoLocation': _isAutoLocation,
      'isSet': isLocationSet,
    };
  }

  // Method to check if location is properly saved
  Future<bool> hasSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString(_prefAddressKey);
      final savedLat = prefs.getDouble(_prefLatKey);
      final savedLng = prefs.getDouble(_prefLngKey);

      return savedAddress != null &&
          savedAddress.isNotEmpty &&
          savedAddress != 'Quetta' &&
          savedLat != null &&
          savedLng != null;
    } catch (e) {
      return false;
    }
  }
}
