import 'package:flutter/material.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationViewModel with ChangeNotifier {
  String _currentLocation = 'Quetta';
  bool _isLoading = false;
  String _error = '';
  double? _latitude;
  double? _longitude;
  bool _isAutoLocation = false;
  List<Map<String, dynamic>> _searchResults = [];

  String get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String get error => _error;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isAutoLocation => _isAutoLocation;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  // In your LocationViewModel class
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

  // Get current location with complete address
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
        _currentLocation = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        _isAutoLocation = true;
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
  void updateLocationManually(String location, {double? lat, double? lng}) {
    _currentLocation = location;
    _latitude = lat;
    _longitude = lng;
    _isAutoLocation = false;
    _error = '';
    notifyListeners();
  }

  bool get isLocationSet =>
      _currentLocation.isNotEmpty && _currentLocation != 'Quetta';

  Map<String, dynamic> get locationData {
    return {
      'address': _currentLocation,
      'latitude': _latitude,
      'longitude': _longitude,
      'isAutoLocation': _isAutoLocation,
    };
  }
}
